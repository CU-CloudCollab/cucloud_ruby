module Cucloud
  # ElbUtils class - methods related to elb
  class ElbUtils
    def initialize(s3 = Aws::S3::Client.new)
      @s3 = s3
    end

    def enable_logging(elb_name, app_name, policy, _elb = Aws::ElasticLoadBalancing::Client.new)
      ## Added by Scott Ross
      ## Stand alone script found here: https://github.com/CU-CloudCollab/elb-logging/
      ## Manual process: http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/enable-access-logs.html

      bucket_name = "#{elb_name}-logging"

      @s3.create_bucket(bucket: bucket_name)
      s3.put_bucket_policy(bucket: bucket_name,
                           policy: policy.to_json)

      elb_client.modify_load_balancer_attributes(load_balancer_name: elb_name, # required
                                                 load_balancer_attributes: {
                                                   access_log: {
                                                     enabled: true, # required
                                                     s3_bucket_name: bucket_name,
                                                     emit_interval: 5,
                                                     s3_bucket_prefix: app_name
                                                   }
                                                 })
      s3.list_objects(bucket: bucket_name).contents.length == 1 ? 0 : 1
    end
  end
end
