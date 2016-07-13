require 'aws-sdk'

# Main Cucloud Module namespace and defaults
module Cucloud
  require 'cucloud/version'
  require 'cucloud/ec2_utils'
  require 'cucloud/asg_utils'
  require 'cucloud/ssm_utils'

  DEFAULT_REGION = 'us-east-1'.freeze

  Aws.config = { region: DEFAULT_REGION }

  def region
    @region
  end

  def region=(region)
    @region = region
    Aws.config = { region: @region }
  end

  module_function :region, :region=
end
