module Cucloud
  # EC2Utils class - anything ec2 related goes here!
  class Ec2Utils
    # This is the command sent to ubuntu for patching
    UBUNTU_PATCH_COMMAND = 'apt-get update; apt-get -y upgrade; reboot'.freeze
    # This is the command sent to amazon linux machines for patching
    AMAZON_PATCH_COMMAND = 'yum update -y; reboot & disown '.freeze
    # Used in time calculations
    SECONDS_IN_A_DAY = 86_400
    # Max attemps for a waiter to try
    WAITER_MAX_ATTEMPS = 240
    # Delay between calls used by waiter to check status
    WAITER_DELAY = 15

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

    # Set the name of the instance that will be displayed in the ec2 console
    def rename_instance(instance, name)
    end

    # reboot instance
    def reboot_instance(instance)
      i = get_instance(instance)
      i.reboot
    end

    # Terminate ec2 instance for a specific instance number.
    def terminate_instance(instance)
      i = get_instance(instance)
      if i.exists?
        case i.state.code
        when 48 # terminated
          raise "#{id} is already terminated"
        else
          i.terminate
        end
      end
    end

    # Assoications an Elastic IP adress with a specific instance number.
    # @return association_id as a string in the form of eipassoc-569cd631.
    #  This is the link between between the
    #  elastic network interface and the elastic IP address.
    def associate_eip(instance, allocation_id)
    end

    # Create ec2 instance based on parameters provided. The function will pull
    #   in default information from ?????.
    # @param options [hash] will be hash that will override the default
    def create_instance(options)
    end

    # Remove private AMI
    def deregister_image(image)
    end

    # Find ami based on a search of Name
    def find_ami(name)
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

    # Preforms a backup on volumes that do not have a recent snapshot_info
    # @param days [Integer] defaults to 5
    # @return [Array<Hash>]  An array of hashes containing snapshot_id, instance_name and volume
    def backup_volumes_unless_recent_backup(days = 5)
      volumes_backed_up_recently = volumes_with_snapshot_within_last_days(days)
      snapshots_created = []

      volumes = @ec2.describe_volumes(filters: [{ name: 'attachment.status', values: ['attached'] }])
      volumes.volumes.each do |volume|
        next if volumes_backed_up_recently[volume.volume_id.to_s]
        instance_name = get_instance_name(volume.attachments[0].instance_id)

        tags = instance_name ? [{ key: 'Instance Name', value: instance_name }] : []
        snapshot_info = create_ebs_snapshot(volume.volume_id,
                                            'auto-ebs-snap-' + Time.now.strftime('%Y-%m-%d-%H:%M:%S'),
                                            tags)

        snapshots_created.push(snapshot_id: snapshot_info.snapshot_id,
                               instance_name: instance_name,
                               volume: volume.volume_id)
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
        if snapshot.start_time > Time.now - (SECONDS_IN_A_DAY * days)
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
          snapshot_days_old = (Time.now.to_i - snapshot.start_time.to_i) / SECONDS_IN_A_DAY

          if snapshot_days_old > days_old
            found_snapshots.push(snapshot.snapshot_id)
          end
        else
          found_snapshots.push(snapshot.snapshot_id)
        end
      end
      found_snapshots
    end
  end
end
