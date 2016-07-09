module Cucloud
  # AsgUtils - Utilities for autoscaling groups
  class AsgUtils
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
    def get_launch_config_by_name(launch_config_name)
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/AutoScaling/Client.html#describe_launch_configurations-instance_method
      lc_desc = @asg.describe_launch_configurations(launch_configuration_names: [launch_config_name])
      lc_desc.launch_configurations[0]
    end
  end
end
