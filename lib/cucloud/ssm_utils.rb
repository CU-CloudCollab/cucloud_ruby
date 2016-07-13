module Cucloud
  # SSMUtils class - for interacting with the simple server management service
  class SSMUtils
    def initialize(ssm_client = Aws::SSM::Client.new)
      @ssm = ssm_client
    end

    def send_patch_command(patch_instances, command)
      @ssm.send_command(
        instance_ids: patch_instances, # required
        document_name: 'AWS-RunShellScript', # required
        timeout_seconds: 600,
        comment: 'Patch It!',
        parameters: {
          'commands' => [command]
        }
      )
    end
  end
end
