class Cucloud::ElbUtils
  def initialize(s3 = Aws::S3::Client.new)
    @s3 = s3
  end

  def enable_logging(elb_name, app_name, policy)
    ## Added by Scott Ross
    ## Part of the 2016 winter hackathon
    ## Stand alone script found here: https://github.com/CU-CloudCollab/elb-logging/

    ## Todo: 1) Find a home for default policies


  end
end
