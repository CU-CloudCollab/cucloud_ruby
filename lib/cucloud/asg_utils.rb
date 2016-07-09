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
    # @return [Aws::AutoScaling::Types::AutoScalingGroup] AWS SDK autoscale group object matching provided group name
    def get_asg_by_name(name)
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/AutoScaling/Client.html#describe_auto_scaling_groups-instance_method
      asg_desc = @asg.describe_auto_scaling_groups(auto_scaling_group_names: [name])

      # nil if not found -> we're accepting one name, so return first result
      asg_desc.auto_scaling_groups[0]
    end
  end
end
