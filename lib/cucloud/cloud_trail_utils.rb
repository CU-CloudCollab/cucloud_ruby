module Cucloud
  # CloudTrailUtils - Utilities for Cloud Trail
  class CloudTrailUtils
    # Regex used to determine if a cloudtrail rule belongs to ITSO
    ITSO_CLOUDTRAIL_ARN_REGEX = %r{arn:aws:cloudtrail:us-east-1:.*:trail\/.*[Ii][Tt][Ss][Oo].*}

    # Constructor for CloudTrailUtils class
    # @param ct_client [Aws::CloudTrail::Client] AWS CloudTrail SDK Client
    def initialize(ct_client = Aws::CloudTrail::Client.new, cs_utils = Cucloud::ConfigServiceUtils.new)
      ## DI for testing purposes
      @ct = ct_client
      @cs_utils = cs_utils
      @region = Cucloud.region
    end

    # Get all cloud trails for this region
    # @return [Array<Aws::CloudTrail::Types::Trail>]
    def get_cloud_trails
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/CloudTrail/Client.html#describe_trails-instance_method
      @ct.describe_trails(include_shadow_trails: false).trail_list
    end

    # Get all cloud trails for this region
    # @return [Aws::CloudTrail::Types::Trail]
    def get_cloud_trail_by_name(trail_name)
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/CloudTrail/Client.html#describe_trails-instance_method
      @ct.describe_trails(trail_name_list: [trail_name], include_shadow_trails: false).trail_list.first
    end

    # Is this trail a global trail
    # @param [Aws::CloudTrail::Types::Trail]
    # @return [Aws::CloudTrail::Types::GetTrailStatusResponse]
    def get_trail_status(trail)
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/CloudTrail/Client.html#get_trail_status-instance_method
      @ct.get_trail_status(name: trail.name)
    end

    # Is this trail a global trail
    # @param [Aws::CloudTrail::Types::Trail]
    # @return [Boolean]
    def global_trail?(trail)
      trail.include_global_service_events && trail.is_multi_region_trail
    end

    # Is Cornell ITSO Trail?
    # @param [Aws::CloudTrail::Types::Trail]
    # @return [Boolean]
    def cornell_itso_trail?(trail)
      !(trail.trail_arn =~ ITSO_CLOUDTRAIL_ARN_REGEX).nil?
    end

    # Is this trail logging?
    # @param [Aws::CloudTrail::Types::Trail]
    # @return [Boolean]
    def trail_logging_active?(trail)
      status = get_trail_status(trail)
      status.is_logging && !status.latest_delivery_time.nil?
    end

    # Get hours since last delivery
    # @param [Aws::CloudTrail::Types::Trail]
    # @return [Integer] Hours
    def hours_since_last_delivery(trail)
      status = get_trail_status(trail)
      return nil if status.latest_delivery_time.nil?

      ((Time.now - status.latest_delivery_time) / 60 / 60).to_i
    end
  end
end
