require 'spec_helper'

describe Cucloud::VpcUtils do
  let(:vpc_client) do
    Aws::EC2::Client.new(stub_responses: true)
  end

  let(:vpc_utils) do
    Cucloud::VpcUtils.new vpc_client
  end

  describe '#compare_nacls' do
    it 'should not throw an exception' do
      ret = vpc_utils.compare_nacls(
        ['us-east-1'],
        [{ cidr: '0.0.0.0/0', egress: true, protocol: '6', from: 80, to: 80 }]
      )
      puts ret.inspect
    end
  end
end
