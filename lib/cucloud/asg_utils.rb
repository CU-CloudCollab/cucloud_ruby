module Cucloud
  # AsgUtils - Utilities for AutoScaling groups
  class AsgUtils
    require 'uuid'

    # Constructor for AsgUtils class
    # @param asg_client [Aws::AutoScaling::Client] AWS AutoScaling SDK Client
    def initialize(asg_client = Aws::AutoScaling::Client.new)
      ## DI for testing purposes
      @asg = asg_client
    end

    # Get an autoscale instance by group name
    # @param name [String] A single autoscale group name
    # @return [Aws::AutoScaling::Types::AutoScalingGroup] AWS SDK autoscale group struct
    def get_asg_by_name(name)
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/AutoScaling/Client.html#describe_auto_scaling_groups-instance_method
      asg_desc = @asg.describe_auto_scaling_groups(auto_scaling_group_names: [name])

      # nil if not found -> we're accepting one name, so return first result
      asg_desc.auto_scaling_groups[0]
    end

    # get an instance of the launch configuration for a given autoscaling group
    # @param launch_config_name [String] Name of launch configuration (from ASG)
    # @return [Aws::AutoScaling::Types::LaunchConfiguration] AWS SDK Launch Configuration struct
    def get_launch_configuration_by_name(launch_config_name)
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/AutoScaling/Client.html#describe_launch_configurations-instance_method
      @asg.describe_launch_configurations(launch_configuration_names: [launch_config_name]).first
    end

    # Generate a hash that can be submitted when creating a new launch config - replace image with desired AMI
    # @param launch_config [Aws::AutoScaling::Types::LaunchConfiguration] Existing launch configuration
    # @param new_ami_id [String] Id of AMI that should be added to the new configuration
    # @param new_launch_config_name [String] Name of new launch configuration (must be unique in AWS account)
    # @return [Hash] Options hash to be submitted via AWS SDK
    def generate_lc_options_hash_with_ami(launch_config, new_ami_id,
                                          new_launch_config_name = "cucloud-lc-#{UUID.new.generate}")

      # make sure we got a valid launch config
      raise 'Not a launch configuration struct' unless launch_config.is_a? Aws::AutoScaling::Types::LaunchConfiguration

      # convert to hash (required for aws sdk) and update necessary values
      config_hash = launch_config.to_h
      config_hash[:launch_configuration_name] = new_launch_config_name
      config_hash[:image_id] = new_ami_id

      # request cannot have arn, created_time or keys with empty values
      config_hash.delete_if { |key, value| key == :launch_configuration_arn || key == :created_time || value == '' }
    end

    # Create new launch configuration in AWS
    # @param options [Hash] Options hash to be passed along in request
    # @return [Seahorse::Client::Response] Empty Seahorse Client Response
    def create_launch_configuration(options)
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/AutoScaling/Client.html#create_launch_configuration-instance_method
      @asg.create_launch_configuration(options)
    end

    # Update autoscale group launch configuration
    # @param asg_name [String] AutoScale group name
    # @param launch_config_name [String] Launch configuration name
    # @return [Seahorse::Client::Response] Empty Seahorse Client Response
    def update_asg_launch_configuration!(asg_name, launch_config_name)
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/AutoScaling/Client.html#update_auto_scaling_group-instance_method
      @asg.update_auto_scaling_group(auto_scaling_group_name: asg_name,
                                     launch_configuration_name: launch_config_name)
    end
  end
end
