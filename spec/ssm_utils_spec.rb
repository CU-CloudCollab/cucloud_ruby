require 'spec_helper'

describe Cucloud::SSMUtils do
  let(:ssm_client) do
    Aws::SSM::Client.new(stub_responses: true)
  end

  let(:ssm_utils) do
    Cucloud::SSMUtils.new ssm_client
  end

  describe '#send_patch_command' do
    it 'should send a SSM coman' do
      ssm_client.stub_responses(
        :send_command, command: { command_id: '1' }
      )

      expect { ssm_utils.send_patch_command(['i-1'], 'some command') }.not_to raise_error
    end
  end
end
