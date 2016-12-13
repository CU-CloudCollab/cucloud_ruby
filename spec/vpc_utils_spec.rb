require 'spec_helper'

describe Cucloud::VpcUtils do
  let(:vpc_client) do
    Aws::EC2::Client.new(stub_responses: true)
  end

  let(:vpc_utils) do
    Cucloud::VpcUtils.new vpc_client
  end

  describe '#compare_nacls' do
    before do
      vpc_client.stub_responses(
        :describe_network_acls,
        network_acls: [
          {
            network_acl_id: 'acl-4a3ba42f',
            entries: [
              {
                rule_number: 200,
                protocol: '6',
                port_range: {
                  to: 80,
                  from: 80
                },
                egress: true,
                rule_action: 'allow',
                cidr_block: '0.0.0.0/0'
              },
              {
                rule_number: 100,
                protocol: '-1',
                egress: true,
                rule_action: 'allow',
                cidr_block: '10.0.0.0/8'
              }
            ]
          },
          {
            network_acl_id: 'acl-4a3ba42d',
            entries: [
              {
                rule_number: 200,
                protocol: '6',
                port_range: {
                  to: 80,
                  from: 80
                },
                egress: true,
                rule_action: 'allow',
                cidr_block: '0.0.0.0/0'
              }
            ]
          }
        ]
      )
    end

    it 'should throw ArgumentErrow if rules is not an array' do
      expect do
        vpc_utils.compare_nacls(cidr: '0.0.0.0/0', egress: true, protocol: '6', from: 80, to: 80)
      end.to raise_error(ArgumentError)
    end

    it 'missing shoud be empty for TCP 80-80 on 0.0.0.0/0' do
      expect(vpc_utils.compare_nacls(
        [{ cidr: '0.0.0.0/0', egress: true, protocol: '6', from: 80, to: 80 }]
      )[0][:missing]).to be_empty
    end

    it 'missing shoud not be empty for TCP 82-82 on 0.0.0.0/0' do
      expect(vpc_utils.compare_nacls(
        [{ cidr: '0.0.0.0/0', egress: true, protocol: '6', from: 82, to: 82 }]
      )[0][:missing]).not_to be_empty
    end

    it 'should not be empty for TCP 80-80 on 0.0.0.0/0 for any ACL' do
      expect(vpc_utils.compare_nacls(
        [{ cidr: '0.0.0.0/0', egress: true, protocol: '6', from: 80, to: 80 }]
      ).count { |x| x[:missing].empty? }).to eq 2
    end

    it 'additional shoud not be empty for acl-4a3ba42f, no rule provided' do
      expect(vpc_utils.compare_nacls(
        []
      )[0][:additional]).not_to be_empty
    end

    it 'should skip acl-4a3ba42f when added to the skip array' do
      expect(vpc_utils.compare_nacls(
        [{ cidr: '0.0.0.0/0', egress: true, protocol: '6', from: 82, to: 82 }],
        ['acl-4a3ba42f']
      ).find { |x| x[:acl] == 'acl-4a3ba42f' }).to be_nil
    end

    it 'should not mutate rules array' do
      rules = [{ cidr: '0.0.0.0/0', egress: true, protocol: '6', from: 80, to: 80 }]
      vpc_utils.compare_nacls(rules)
      expect(rules.length).to be 1
    end
  end

  context 'while vpc responses stubbed out with flow logs enabled' do
    before do
      vpc_client.stub_responses(
        :describe_vpcs,
        vpcs: [
          {
            vpc_id: 'test-vpc',
            state: 'available',
            cidr_block: '10.0.0.0/24',
            dhcp_options_id: 'dopt-1a2b3c4d2',
            tags: [
              {
                key: 'tagname',
                value: 'tagvalue'
              }
            ],
            instance_tenancy: 'default',
            is_default: true
          }
        ]
      )

      vpc_client.stub_responses(
        :describe_flow_logs,
        flow_logs: [
          {
            creation_time: Time.now,
            flow_log_id: 'test-id',
            flow_log_status: 'active',
            resource_id: 'test-vpc',
            traffic_type: 'ACCEPT',
            log_group_name: 'log-group',
            deliver_logs_status: 'active',
            deliver_logs_error_message: 'test',
            deliver_logs_permission_arn: 'permission-arn'
          }
        ]
      )
    end

    describe '#flow_logs?' do
      it 'should return true' do
        expect(vpc_utils.flow_logs?).to be true
      end
    end

    describe '#vpc_flow_log_status?' do
      it 'should return expected vpc_id' do
        expect(vpc_utils.vpc_flow_log_status[0][:vpc_id]).to eq 'test-vpc'
      end

      it 'should return expected flow log status (true)' do
        expect(vpc_utils.vpc_flow_log_status[0][:flow_logs_active]).to eq true
      end
    end
  end

  context 'while vpc responses stubbed out without flow logs' do
    before do
      vpc_client.stub_responses(
        :describe_vpcs,
        vpcs: [
          {
            vpc_id: 'test-vpc',
            state: 'available',
            cidr_block: '10.0.0.0/24',
            dhcp_options_id: 'dopt-1a2b3c4d2',
            tags: [
              {
                key: 'tagname',
                value: 'tagvalue'
              }
            ],
            instance_tenancy: 'default',
            is_default: true
          }
        ]
      )

      vpc_client.stub_responses(
        :describe_flow_logs,
        flow_logs: [

        ]
      )
    end

    describe '#flow_logs?' do
      it 'should return true' do
        expect(vpc_utils.flow_logs?).to be false
      end
    end

    describe '#vpc_flow_log_status?' do
      it 'should return expected vpc_id' do
        expect(vpc_utils.vpc_flow_log_status[0][:vpc_id]).to eq 'test-vpc'
      end

      it 'should return expected flow log status (true)' do
        expect(vpc_utils.vpc_flow_log_status[0][:flow_logs_active]).to eq false
      end
    end
  end
end
