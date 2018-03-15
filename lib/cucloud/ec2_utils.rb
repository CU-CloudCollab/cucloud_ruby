module Cucloud
  # EC2Utils class - anything ec2 related goes here!
  class Ec2Utils
    # This is the command sent to ubuntu for patching
    UBUNTU_PATCH_COMMAND = 'apt-get update; apt-get -y upgrade; reboot'.freeze
    # This is the command sent to amazon linux machines for patching
    AMAZON_PATCH_COMMAND = 'yum update -y; reboot & disown '.freeze
    # Max attemps for a waiter to try
    WAITER_MAX_ATTEMPS = 240
    # Delay between calls used by waiter to check status
    WAITER_DELAY = 15
    # Two weeks in hours
    TWO_WEEKS = 336
    # Default OS to use
    DEFAULT_OS = 'Linux/UNIX'.freeze

    def initialize(ec2_client = Aws::EC2::Client.new, ssm_utils = Cucloud::SSMUtils.new)
      @ec2 = ec2_client
      @ssm_utils = ssm_utils
    end

    # Get instance object
    # @param instance_id [String] instance id in the format of i-121231231231
    # @return [Aws::EC2::Instance] Object representing the intance see
    # http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Instance.html
    def get_instance(instance_id)
      Aws::EC2::Instance.new(id: instance_id, client: @ec2)
    end

    # Get instance information for a specific instance
    # @param instance [String] instance id in the format of i-121231231231
    # @return [array] aws reservations see
    #  http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#describe_instances-instance_method
    def get_instance_information(instance)
      @ec2.describe_instances(instance_ids: [instance])
    end

    # Stop ec2 instance for a specific instance number. The function will wait
    # until the instance has entered the stopped state.
    # @param instance [String] instance id in the format of i-121231231231
    def stop_instance(instance)
      @ec2.stop_instances(instance_ids: [instance])
    end

    # Start ec2 instance for a specific instance number. The function will wait
    #   until the instance has entered the running state.
    # @param instance [String] instance id in the format of i-121231231231
    def start_instance(instance)
      @ec2.start_instances(instance_ids: [instance])
    end

    # reboot instance
    def reboot_instance(instance)
      i = get_instance(instance)
      i.reboot
    end

    # Terminate ec2 instance for a specific instance number.
    def terminate_instance(instance)
      i = get_instance(instance)
      i.terminate
    end

    # Based on tag name and value, return instances
    # @param tag_name [string] name of tag
    # @param tag_value [string] the value of the tag
    # @return [array] aws reservations see
    #  http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#describe_instances-instance_method
    def get_instances_by_tag(tag_name, tag_value)
      @ec2.describe_instances(filters: [
                                {
                                  name: "tag:#{tag_name}",
                                  values: tag_value
                                }
                              ])
    end

    # stop instances based on a tag name and value
    # @param tag_name [string] name of tag
    # @param tag_value [string] the value of the tag
    def stop_instances_by_tag(tag_name, tag_value)
      get_instances_by_tag(tag_name, tag_value).reservations[0].instances.each do |i|
        @ec2.stop_instances(instance_ids: [i.instance_id])
      end
    end

    # start instances based on a tag name and value
    # @param tag_name [string] name of tag
    # @param tag_value [string] the value of the tag
    def start_instances_by_tag(tag_name, tag_value)
      get_instances_by_tag(tag_name, tag_value).reservations[0].instances.each do |i|
        @ec2.start_instances(instance_ids: [i.instance_id])
      end
    end

    # patch instances based on a tag name and value
    # @param tag_name [string] name of tag
    # @param tag_value [string] the value of the tag
    def instances_to_patch_by_tag(tag_name = 'auto_patch', tag_value = ['1'])
      resp = get_instances_by_tag(tag_name, tag_value)

      ubuntu_patch_instances = []
      amazon_patch_instances = []
      all_instances = []

      resp.reservations.each do |res|
        res.instances.each do |instance|
          instance.tags.each do |tag|
            next unless tag.key.eql?('os')
            if tag.value.eql?('ubuntu')
              ubuntu_patch_instances.push(instance.instance_id)
              all_instances.push(instance.instance_id)
            elsif tag.value.eql?('ecs') || tag.value.eql?('amazon')
              amazon_patch_instances.push(instance.instance_id)
              all_instances.push(instance.instance_id)
            end
          end
        end
      end

      @ssm_utils.send_patch_command(ubuntu_patch_instances, UBUNTU_PATCH_COMMAND) if ubuntu_patch_instances.any?
      @ssm_utils.send_patch_command(amazon_patch_instances, AMAZON_PATCH_COMMAND) if amazon_patch_instances.any?

      all_instances
    end

    # Get the nice name of the ec2 intsance from the 'Name" tag'
    # @param instance_id [String] instance id in the format of i-121231231231
    # @return [String] Name of instacnce if found or nil if not found
    def get_instance_name(instance_id)
      instance = get_instance(instance_id)
      tag_name = instance.tags.find { |tag| tag.key.eql?('Name') }
      tag_name ? tag_name.value : nil
    end

    # Create a snapshot of an EBS volume and apply supplied tags
    # will wait 20 minutes for the process to completed
    # @param volume_id [String] volume id in the formate of vol-121231231231
    # @param snapshot_desc [String] Description of the snapshot
    # @param tags [Array] Array of key value pairs to be applied as tags to the snapshot
    # @return snapshot information see
    # http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#create_tags-instance_method
    def create_ebs_snapshot(volume_id, snapshot_desc, tags = [])
      snapshot_info = @ec2.create_snapshot(
        volume_id: volume_id,
        description: snapshot_desc
      )

      @ec2.wait_until(:snapshot_completed, snapshot_ids: [snapshot_info.snapshot_id]) do |w|
        w.max_attempts = WAITER_MAX_ATTEMPS
        w.delay = WAITER_DELAY
      end

      @ec2.create_tags(resources: [snapshot_info.snapshot_id], tags: tags) unless tags.empty?

      snapshot_info
    end

    # Performs a backup on volumes that do not have a recent snapshot_info
    # Tags specified in additional_snapshot_tags[] will take precedence over tags we would
    #    normally create or would have copied from the volume via preserve_tags[].
    # @param days [Integer] defaults to 5
    # @param preserve_volume_tags [Array] Array of tag keys to copy from from volume, if present.
    # @param additional_snapshot_tags [Array] Array of hashes containing additional tags to apply,
    # @return [Array<Hash>]  An array of hashes containing snapshot_id, instance_name and volume
    def backup_volumes_unless_recent_backup(days = 5, preserve_volume_tags = [], additional_snapshot_tags = [])
      volumes_backed_up_recently = volumes_with_snapshot_within_last_days(days)
      snapshots_created = []

      volumes = @ec2.describe_volumes(filters: [{ name: 'attachment.status', values: ['attached'] }])
      volumes.volumes.each do |volume|
        next if volumes_backed_up_recently[volume.volume_id.to_s]
        instance_name = get_instance_name(volume.attachments[0].instance_id)
        tags = additional_snapshot_tags.dup
        unless instance_name.nil? || tags.any? { |tagitem| tagitem[:key] == 'Instance Name' }
          tags << { key: 'Instance Name', value: instance_name }
        end
        volume.tags.each do |tag|
          if preserve_volume_tags.include?(tag.key) && tags.none? { |tagitem| tagitem[:key] == tag.key }
            tags << tag
          end
        end

        snapshot_info = create_ebs_snapshot(volume.volume_id,
                                            'auto-ebs-snap-' + Time.now.strftime('%Y-%m-%d-%H:%M:%S'),
                                            tags)

        snapshots_created.push(snapshot_id: snapshot_info.snapshot_id,
                               instance_name: instance_name,
                               volume: volume.volume_id,
                               tags: tags)
      end

      snapshots_created
    end

    # Find volumes that have a recent snapshot
    # @param days [Integer] defaults to 5
    # @return [Array] list of volume ids that have recent snapshots
    def volumes_with_snapshot_within_last_days(days = 5)
      volumes_backed_up_recently = {}

      snapshots = @ec2.describe_snapshots(owner_ids: ['self'], filters: [{ name: 'status', values: ['completed'] }])
      snapshots.snapshots.each do |snapshot|
        if snapshot.start_time > Time.now - (Cucloud::SECONDS_IN_A_DAY * days)
          volumes_backed_up_recently[snapshot.volume_id.to_s] = true
        end
      end
      volumes_backed_up_recently
    end

    # Find snapshots with supplied properties, currently only supports days_old
    # @param options [Hash]
    # @return [Array] list of snapshot ids
    def find_ebs_snapshots(options = {})
      days_old = options[:days_old]
      found_snapshots = []
      snapshots = @ec2.describe_snapshots(owner_ids: ['self'], filters: [{ name: 'status', values: ['completed'] }])

      snapshots.snapshots.each do |snapshot|
        if !days_old.nil?
          snapshot_days_old = (Time.now.to_i - snapshot.start_time.to_i) / Cucloud::SECONDS_IN_A_DAY

          if snapshot_days_old > days_old
            found_snapshots.push(snapshot.snapshot_id)
          end
        else
          found_snapshots.push(snapshot.snapshot_id)
        end
      end
      found_snapshots
    end

    # Get a recommendation for a spot bid request.  Given an instance type and
    # OS we will grab data from a period specified, default is from two weeks to now,
    # and calculate recommendations for the AZs in the current region
    # @param instance_type [String] Insrance type to get bid for
    # @param os [String] OS you whish to run, default linux
    # @param num_hours [Integer] How many hours to look back, default two weeks
    # @return [Hash] Reccomendations by region, empty if no viable recommendations
    def best_spot_bid_price(instance_type, os = DEFAULT_OS, num_hours = TWO_WEEKS)
      price_history_by_az = {}
      recommendations = {}

      options = {
        end_time: Time.now.utc,
        instance_types: [
          instance_type
        ],
        product_descriptions: [
          os
        ],
        start_time: (Time.now - num_hours * 60).utc
      }

      loop do
        price_history = @ec2.describe_spot_price_history(options)
        price_history.spot_price_history.each do |price|
          price_history_by_az[price.availability_zone] = [] unless price_history_by_az[price.availability_zone]
          price_history_by_az[price.availability_zone].push(price.spot_price.to_f)
        end

        break if price_history.next_token.nil? || price_history.next_token.empty?
        options[:next_token] = price_history.next_token
      end

      price_history_by_az.each do |key, data|
        stats = data.descriptive_statistics
        next unless stats[:number] > 30
        confidence_interval = Cucloud::Utilities.confidence_interval_99(
          stats[:mean],
          stats[:standard_deviation],
          stats[:number]
        )
        recommendations[key] = confidence_interval[1]
      end

      recommendations
    end

    # Make spot instance request
    # @param options [Hash] Options to provide to the API
    # see http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#request_spot_instances-instance_method
    # @return [Hash] Description of the spot request
    def make_spot_instance_request(options)
      spot_requests = @ec2.request_spot_instances(options)
      request_ids = [spot_requests.spot_instance_requests[0].spot_instance_request_id]

      @ec2.wait_until(:spot_instance_request_fulfilled, spot_instance_request_ids: request_ids)
      @ec2.describe_spot_instance_requests(spot_instance_request_ids: request_ids)
    end
  end
end
