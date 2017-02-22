module Cucloud
  # RdsUtils class - for interacting with the AWS relational database service
  class RdsUtils
    def initialize(rds_client = Aws::RDS::Client.new)
      @rds = rds_client
    end

    # Get the RDS instance object with the given name
    # @param db_instance_identifier [String] RDS instance identifier (e.g., "jadu-test-dev")
    # @return [Aws::RDS::DBInstance] the instance object
    def get_instance(db_instance_identifier)
      resource = Aws::RDS::Resource.new(client: @rds)
      resource.db_instance(db_instance_identifier)
    end

    # Determine if a givne db instance exist
    # @param db_instance_identifier [String] RDS instance identifier
    # @return [boolean]
    def does_db_exist?(db_instance_identifier)
      get_instance(db_instance_identifier).instance_create_time
      true
    rescue Aws::RDS::Errors::DBInstanceNotFound
      false
    end

    def delete_db_instance(db_instance_identifier, db_snapshot_identifier = nil)
      if does_db_exist?(db_instance_identifier)
        if db_snapshot_identifier.nil?
          @rds.delete_db_instance(db_instance_identifier: db_instance_identifier, skip_final_snapshot: true)
        else
          @rds.delete_db_instance(db_instance_identifier: db_instance_identifier, final_db_snapshot_identifier: db_snapshot_identifier)
        end

        @rds.wait_until(:db_instance_deleted, db_instance_identifier: db_instance_identifier)
      else
        raise Aws::RDS::Errors::DBInstanceNotFound.new(db_instance_identifier, '')
      end
    end

    # def restore_db(options)
    #   db_id = options[:db_instance_identifier]
    #   db_subnet_group_name = if options[:db_subnet_group_name].nil?
    #                            'private'
    #                          else
    #                            options[:db_subnet_group_name]
    #                          end
    #   puts "SUBNET GROUP NAME #{db_subnet_group_name}"
    #
    #   restore_from = options[:restore_from] || 'clkprod'
    #
    #   if !does_db_exist?(db_id)
    #     db_name = options[:db_name]
    #     db_snapshot_identifier = options[:db_snapshot_identifier].nil? ? find_latest_snapshot(db_instance_identifier: restore_from) : options[:db_snapshot_identifier]
    #     db_instance_class = options[:db_instance_class].nil? ? 'db.t2.large' : options[:db_instance_class]
    #     db_option_group = options[:option_group_name].nil? ? 'kuali-oracle-options' : options[:option_group_name]
    #
    #     @RDS.client.restore_db_instance_from_db_snapshot(db_name: db_name,
    #                                                      db_instance_identifier: db_id,
    #                                                      db_snapshot_identifier: db_snapshot_identifier,
    #                                                      db_instance_class: db_instance_class,
    #                                                      db_subnet_group_name: db_subnet_group_name,
    #                                                      availability_zone: 'us-east-1d',
    #                                                      option_group_name: db_option_group)
    #   else
    #     puts "#{db_id} already exist"
    #   end
    # end

    def find_latest_snapshot(db_instance_identifier)
      latest_snapshot_time = Time.new(2002)
      latest_snap_shot = nil
      snapshots_info = @rds.describe_db_snapshots(db_instance_identifier: db_instance_identifier)[:db_snapshots]

      snapshots_info.each do |snapshot_info|
        next if snapshot_info[:status] != 'available'

        if latest_snapshot_time.to_i < snapshot_info[:snapshot_create_time].to_i
          latest_snapshot_time = snapshot_info[:snapshot_create_time].to_i
          latest_snap_shot = snapshot_info
        end
      end

       latest_snap_shot.nil? ? nil : latest_snap_shot[:db_snapshot_identifier]
    end

    # Begins the creation of a snapshot of the given RDS instance.
    # This is a non-blocking call so it will return before the snapshot
    # is created and available.
    # @param rds_instance [Aws::RDS::DBInstance] the RDS instance which to snapshot
    # @param tags [Array<Hash>] tags to assign to the snapshot;
    #   each array element should be of the form { key: "some key", value: "some value" }
    # @return [Aws::RDS::DBSnapshot] handle to the new snapshot
    def start_snapshot(rds_instance, tags = [])
      date = Time.new
      snap_id = rds_instance.db_instance_identifier + '-' + date.year.to_s + '-' \
          + zerofill2(date.month) + '-' + zerofill2(date.day) + '-' \
          + zerofill2(date.hour) + '-' + zerofill2(date.min)
      rds_instance.create_snapshot(
        db_snapshot_identifier:  snap_id,
        tags: tags
      )
    end

    # Return list of pending snapshots for the instance.
    # New snapshots cannot be created if there are any snapshots in the process
    # of being created for the given instance.
    # @param rds_instance [Aws::RDS::DBInstance] the RDS instance to examine
    # @return [Collection<Aws::RDS::DBSnapshot>] the collection of snapshots in the process of being created
    def pending_snapshots(rds_instance)
      snaps = rds_instance.snapshots
      snaps.select do |snap|
        snap.status == 'creating'
      end
    end

    # Wait for the completion and availability of a snapshot.
    # @param snapshot [Aws::RDS::DBSnapshot] the snapshot of interest
    # @param max_attempts [Integer] (optional) maximum number of times to poll the snapshot
    #   for status updates; defaults to nil which polls indefinitely
    # @param delay [Integer] (optional) number of seconds to delay between polling;
    #   defaults to 10
    # @return [Aws::RDS::DBSnapshot] snapshot with updated attributes;
    #   returns nil if the snapshot did not complete within the allowed time.
    def wait_until_snapshot_available(snapshot, max_attempts = nil, delay = 10)
      snapshot.wait_until(max_attempts: max_attempts, delay: delay) do |snap|
        # Status == available is a conservative test for completion.
        # A more liberal test would be percent_progress == 100.
        snap.status == 'available'
      end
    rescue Aws::Waiters::Errors::WaiterFailed
      nil
    end

    # Create a new snapshot of the instance, if no snapshots are already
    # in the process of being created, and wait indefinitely
    # until the snapshot is complete.
    # @param rds_instance [Aws::RDS::DBInstance] the RDS instance which to snapshot
    # @param tags [Array<Hash>] tags to assign to the snapshot;
    #   each array element should be of the form { key: "some key", value: "some value" }
    # @return  [Aws::RDS::DBSnapshot] handle to the new snapshot;
    #   nil if a new snapshot cannot be created because of other pending snapshots
    def create_snapshot_and_wait_until_available(rds_instance, tags = [])
      return nil unless pending_snapshots(rds_instance).empty?
      snap = start_snapshot(rds_instance, tags)
      wait_until_snapshot_available(snap, nil, 10)
    end

    private

    # Return the given non-negative number as a string, zero-padded to 2 digits.
    # @param n [Integet] a number 0-99
    # @return [String] the zero-padded string
    def zerofill2(n)
      n.to_s.rjust(2, '0')
    end
  end
end
