require 'spec_helper'

## Written by Scott Ross
## Unit testing ec2_utils
## Spring 2016

describe Cucloud::Ec2Utils do
  let(:ec2_client) do
    Aws::EC2::Client.new(stub_responses: true)
  end

  let(:ssm_client) do
    Aws::SSM::Client.new(stub_responses: true)
  end

  let(:ssm_utils) do
    Cucloud::SSMUtils.new ssm_client
  end

  let(:ec_util) do
    Cucloud::Ec2Utils.new ec2_client, ssm_utils
  end

  context 'while ec2 is stubbed out' do
    before do
      ec2_client.stub_responses(
        :describe_instances,
        next_token: nil,
        reservations: [{
          instances: [
            { instance_id: 'i-1',
              state: { name: 'running' },
              tags: [
                { key: 'Name', value: 'example-1' }
              ] }
          ]
        }]
      )

      ec2_client.stub_responses(
        :describe_snapshots,
        snapshots: [
          { snapshot_id: 'snap-abc',
            start_time: Time.now - (Cucloud::Ec2Utils::SECONDS_IN_A_DAY * 4),
            state: 'completed',
            owner_id: '123456789012',
            volume_id: 'vol-abc' },
          { snapshot_id: 'snap-def',
            start_time: Time.now - (Cucloud::Ec2Utils::SECONDS_IN_A_DAY * 10),
            state: 'completed',
            owner_id: '123456789012',
            volume_id: 'vol-def' }
        ]
      )

      ec2_client.stub_responses(
        :describe_volumes,
        volumes: [
          { volume_id: 'vol-abc' },
          { volume_id: 'vol-def',
            attachments: [
              instance_id: 'i-1'
            ] }
        ]
      )

      ec2_client.stub_responses(
        :create_snapshot,
        snapshot_id: 'snap-def'
      )

      ec2_client.stub_responses(
        :create_tags, {}
      )
    end

    it '.new default optional should be successful' do
      expect(Cucloud::Ec2Utils.new).to be_a_kind_of(Cucloud::Ec2Utils)
    end

    it 'dependency injectin ec2_client should be successful' do
      expect(Cucloud::Ec2Utils.new(ec2_client)).to be_a_kind_of(Cucloud::Ec2Utils)
    end

    it "'get_instances_by_tag' should return '> 1' where tage_name= Name, and tag_value= example-1" do
      expect(ec_util.get_instances_by_tag('Name', ['example-1']).to_a.size).to eq 1
    end

    it "'stop_instances_by_tag' should return without an error" do
      expect { ec_util.stop_instances_by_tag('Name', ['example-1']) }.not_to raise_error
    end

    it "'start_instances_by_tag' should return without an error" do
      expect { ec_util.start_instances_by_tag('Name', ['example-1']) }.not_to raise_error
    end

    it "should 'get_instance_information' and the instance id should eq i-1" do
      expect(ec_util.get_instance_information('i-1').reservations[0].instances[0].instance_id.to_s).to eq 'i-1'
    end

    it "should 'start_instance' without an error" do
      expect { ec_util.start_instance('i-1') }.not_to raise_error
    end

    it "should 'stop_instance' without an error" do
      expect { ec_util.stop_instance('i-1') }.not_to raise_error
    end

    it "should 'terminate_instance' without an error" do
      expect { ec_util.terminate_instance('i-1') }.not_to raise_error
    end

    it "should 'reboot_instance' without an error" do
      expect { ec_util.reboot_instance('i-1') }.not_to raise_error
    end

    it 'should get the instance name tag for i-1' do
      expect(ec_util.get_instance_name('i-1')).to eq 'example-1'
    end

    it 'should find volumes that have no shapshots in the last five days (default)' do
      volumes = ec_util.volumes_with_snapshot_within_last_days
      expect(volumes['vol-abc']).to be true
      expect(volumes['vol-def']).to be_nil
    end

    it 'should backup volumes that do not have a recent snapshot' do
      snapshots_created = ec_util.backup_volumes_unless_recent_backup
      expect(snapshots_created[0][:snapshot_id]).to eq 'snap-def'
      expect(snapshots_created[0][:instance_name]).to eq 'example-1'
      expect(snapshots_created[0][:volume]).to eq 'vol-def'
    end

    it 'should create an ebs snapshot' do
      snapshots_created = ec_util.create_ebs_snapshot('i-1', 'desc')
      expect(snapshots_created[:snapshot_id]).to eq 'snap-def'
    end

    it 'should find snapshots older than 6 days' do
      snapshots_found = ec_util.find_ebs_snapshots(days_old: 6)
      expect(snapshots_found[0]).to eq 'snap-def'
    end

    it 'should find all the snapshots' do
      snapshots_found = ec_util.find_ebs_snapshots
      expect(snapshots_found.length).to eq 2
    end

    it 'should get nil for the instance name tag for i-2' do
      ec2_client.stub_responses(
        :describe_instances,
        next_token: nil,
        reservations: [{
          instances: [
            { instance_id: 'i-2',
              state: { name: 'running' } }
          ]
        }]
      )
      expect(ec_util.get_instance_name('i-2')).to be_nil
    end

    describe '#instances_to_patch_by_tag' do
      it 'should run without an error with no valid targets' do
        expect { ec_util.instances_to_patch_by_tag }.not_to raise_error
      end

      it 'should send the patch commands for ubuntu' do
        ec2_client.stub_responses(
          :describe_instances,
          next_token: nil,
          reservations: [{
            instances: [
              { instance_id: 'i-1',
                state: { name: 'running' },
                tags: [
                  { key: 'Name', value: 'example-1' },
                  { key: 'auto_patch', value: '1' },
                  { key: 'os', value: 'ubuntu' }
                ] }
            ]
          }]
        )

        expect(ssm_utils).to receive(:send_patch_command).with(['i-1'], Cucloud::Ec2Utils::UBUNTU_PATCH_COMMAND)
        ec_util.instances_to_patch_by_tag
      end

      it 'should send the patch commands for ubuntu and amazon' do
        ec2_client.stub_responses(
          :describe_instances,
          next_token: nil,
          reservations: [{
            instances: [
              { instance_id: 'i-1',
                state: { name: 'running' },
                tags: [
                  { key: 'Name', value: 'example-1' },
                  { key: 'auto_patch', value: '1' },
                  { key: 'os', value: 'ubuntu' }
                ] },
              { instance_id: 'i-2',
                state: { name: 'running' },
                tags: [
                  { key: 'Name', value: 'example-1' },
                  { key: 'auto_patch', value: '1' },
                  { key: 'os', value: 'amazon' }
                ] }
            ]
          }]
        )

        expect(ssm_utils).to receive(:send_patch_command).with(['i-1'], Cucloud::Ec2Utils::UBUNTU_PATCH_COMMAND)
        expect(ssm_utils).to receive(:send_patch_command).with(['i-2'], Cucloud::Ec2Utils::AMAZON_PATCH_COMMAND)
        ec_util.instances_to_patch_by_tag
      end
    end
  end
end
