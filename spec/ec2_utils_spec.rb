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
            start_time: Time.now - (Cucloud::SECONDS_IN_A_DAY * 4),
            state: 'completed',
            owner_id: '123456789012',
            volume_id: 'vol-abc' },
          { snapshot_id: 'snap-def',
            start_time: Time.now - (Cucloud::SECONDS_IN_A_DAY * 10),
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

    it 'dependency injection ec2_client should be successful' do
      expect(Cucloud::Ec2Utils.new(ec2_client)).to be_a_kind_of(Cucloud::Ec2Utils)
    end

    it "'get_instances_by_tag' should return '> 1' where tag_name= Name, and tag_value= example-1" do
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

    it 'should find volumes that have no snapshots in the last five days (default)' do
      volumes = ec_util.volumes_with_snapshot_within_last_days
      expect(volumes['vol-abc']).to be true
      expect(volumes['vol-def']).to be_nil
    end

    it 'should backup volumes that do not have a recent snapshot' do
      snapshots_created = ec_util.backup_volumes_unless_recent_backup
      expect(snapshots_created).to match_array(
        [
          snapshot_id: 'snap-def',
          instance_name: 'example-1',
          volume: 'vol-def',
          tags: [
            { key: 'Instance Name', value: 'example-1' }
          ]
        ]
      )
    end

    it 'should include volume tags in snapshots when asked' do
      ec2_client.stub_responses(
        :describe_volumes,
        volumes: [
          { volume_id: 'vol-ghi',
            attachments: [
              instance_id: 'i-1'
            ],
            tags: [
              { key: 'Tag1', value: 'tag-1' },
              { key: 'Tag2', value: 'tag-2' }
            ] },
          { volume_id: 'vol-jkl',
            attachments: [
              instance_id: 'i-1'
            ],
            tags: [
              { key: 'Tag1', value: 'tag-1' },
              { key: 'Tag2', value: 'tag-2' },
              { key: 'Tag3', value: 'tag-3' }
            ] }
        ]
      )
      snapshots_created = ec_util.backup_volumes_unless_recent_backup(5, %w(Tag1 Tag3))
      expect(snapshots_created).to match_array(
        [
          {
            snapshot_id: 'snap-def',
            instance_name: 'example-1',
            volume: 'vol-ghi',
            tags: [
              { key: 'Instance Name', value: 'example-1' },
              Aws::EC2::Types::Tag.new(key: 'Tag1', value: 'tag-1')
            ]
          },
          {
            snapshot_id: 'snap-def',
            instance_name: 'example-1',
            volume: 'vol-jkl',
            tags: [
              { key: 'Instance Name', value: 'example-1' },
              Aws::EC2::Types::Tag.new(key: 'Tag1', value: 'tag-1'),
              Aws::EC2::Types::Tag.new(key: 'Tag3', value: 'tag-3')
            ]
          }
        ]
      )
    end

    it 'should include additional tags in snapshots when asked' do
      ec2_client.stub_responses(
        :describe_volumes,
        volumes: [
          { volume_id: 'vol-ghi',
            attachments: [
              instance_id: 'i-1'
            ],
            tags: [
              { key: 'Tag1', value: 'tag-1' },
              { key: 'Tag2', value: 'tag-2' }
            ] },
          { volume_id: 'vol-jkl',
            attachments: [
              instance_id: 'i-1'
            ],
            tags: [
              { key: 'Tag1', value: 'tag-1' },
              { key: 'Tag2', value: 'tag-2' },
              { key: 'Tag3', value: 'tag-3' }
            ] }
        ]
      )
      snapshots_created = ec_util.backup_volumes_unless_recent_backup(5,
                                                                      %w(Tag1 Tag3),
                                                                      [
                                                                        { key: 'MyTag1', value: 'value-1' },
                                                                        { key: 'MyTag2', value: 'value-2' }
                                                                      ])
      expect(snapshots_created).to match_array(
        [
          {
            snapshot_id: 'snap-def',
            instance_name: 'example-1',
            volume: 'vol-ghi',
            tags: [
              { key: 'MyTag1', value: 'value-1' },
              { key: 'MyTag2', value: 'value-2' },
              { key: 'Instance Name', value: 'example-1' },
              Aws::EC2::Types::Tag.new(key: 'Tag1', value: 'tag-1')
            ]
          },
          {
            snapshot_id: 'snap-def',
            instance_name: 'example-1',
            volume: 'vol-jkl',
            tags: [
              { key: 'MyTag1', value: 'value-1' },
              { key: 'MyTag2', value: 'value-2' },
              { key: 'Instance Name', value: 'example-1' },
              Aws::EC2::Types::Tag.new(key: 'Tag1', value: 'tag-1'),
              Aws::EC2::Types::Tag.new(key: 'Tag3', value: 'tag-3')
            ]
          }
        ]
      )
    end

    it 'should include override volume tags in snapshots when asked' do
      ec2_client.stub_responses(
        :describe_volumes,
        volumes: [
          { volume_id: 'vol-ghi',
            attachments: [
              instance_id: 'i-1'
            ],
            tags: [
              { key: 'Tag1', value: 'tag-1' },
              { key: 'Tag2', value: 'tag-2' }
            ] },
          { volume_id: 'vol-jkl',
            attachments: [
              instance_id: 'i-1'
            ],
            tags: [
              { key: 'Tag1', value: 'tag-1' },
              { key: 'Tag2', value: 'tag-2' },
              { key: 'Tag3', value: 'tag-3' }
            ] }
        ]
      )
      snapshots_created = ec_util.backup_volumes_unless_recent_backup(5,
                                                                      %w(Tag1 Tag3),
                                                                      [
                                                                        { key: 'MyTag1', value: 'value-1' },
                                                                        { key: 'MyTag2', value: 'value-2' },
                                                                        { key: 'Tag3', value: 'value-3' }
                                                                      ])
      expect(snapshots_created).to match_array(
        [
          {
            snapshot_id: 'snap-def',
            instance_name: 'example-1',
            volume: 'vol-ghi',
            tags: [
              { key: 'MyTag1', value: 'value-1' },
              { key: 'MyTag2', value: 'value-2' },
              { key: 'Tag3', value: 'value-3' },
              { key: 'Instance Name', value: 'example-1' },
              Aws::EC2::Types::Tag.new(key: 'Tag1', value: 'tag-1')
            ]
          },
          {
            snapshot_id: 'snap-def',
            instance_name: 'example-1',
            volume: 'vol-jkl',
            tags: [
              { key: 'MyTag1', value: 'value-1' },
              { key: 'MyTag2', value: 'value-2' },
              { key: 'Tag3', value: 'value-3' },
              { key: 'Instance Name', value: 'example-1' },
              Aws::EC2::Types::Tag.new(key: 'Tag1', value: 'tag-1')
            ]
          }
        ]
      )
    end

    it 'should include instance name tag in snapshots when asked' do
      ec2_client.stub_responses(
        :describe_volumes,
        volumes: [
          { volume_id: 'vol-ghi',
            attachments: [
              instance_id: 'i-1'
            ] },
          { volume_id: 'vol-jkl',
            attachments: [
              instance_id: 'i-1'
            ] }
        ]
      )
      snapshots_created = ec_util.backup_volumes_unless_recent_backup(5,
                                                                      %w(),
                                                                      [
                                                                        { key: 'Instance Name',
                                                                          value: 'NOT-example-1' }
                                                                      ])
      expect(snapshots_created).to match_array(
        [
          {
            snapshot_id: 'snap-def',
            instance_name: 'example-1',
            volume: 'vol-ghi',
            tags: [
              { key: 'Instance Name', value: 'NOT-example-1' }
            ]
          },
          {
            snapshot_id: 'snap-def',
            instance_name: 'example-1',
            volume: 'vol-jkl',
            tags: [
              { key: 'Instance Name', value: 'NOT-example-1' }
            ]
          }
        ]
      )
    end

    it 'should not apply instance_name tags to snapshots of instances that have no name tag' do
      ec2_client.stub_responses(
        :describe_instances,
        next_token: nil,
        reservations: [{
          instances: [
            { instance_id: 'i-1',
              state: { name: 'running' },
              tags: [
              ] }
          ]
        }]
      )

      ec2_client.stub_responses(
        :describe_volumes,
        volumes: [
          { volume_id: 'vol-mno',
            attachments: [
              instance_id: 'i-1'
            ] }
        ]
      )
      snapshots_created = ec_util.backup_volumes_unless_recent_backup(5)
      expect(snapshots_created).to match_array(
        [
          {
            snapshot_id: 'snap-def',
            instance_name: nil,
            volume: 'vol-mno',
            tags: []
          }
        ]
      )
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

    describe 'make_spot_instance_request' do
      it 'should make a spot instnace request' do
        ec2_client.stub_responses(
          :describe_spot_instance_requests,
          spot_instance_requests: [{
            status: {
              code: 'fulfilled'
            }
          }]
        )

        ec2_client.stub_responses(
          :request_spot_instances,
          spot_instance_requests: [{
            spot_instance_request_id: 'sir-1212121'
          }]
        )

        options = {
          instance_count: 1,
          launch_specification: {

            image_id: 'ami-275ffe31',
            instance_type: 'm3.medium'
          },
          spot_price: '0.016',
          type: 'one-time'
        }

        expect { ec_util.make_spot_instance_request(options) }.not_to raise_error
      end
    end

    describe 'best_spot_bid_price' do
      it 'should return a list of bid recommendations' do
        ec2_client.stub_responses(
          :describe_spot_price_history,
          JSON.parse(File.read(File.join(File.dirname(__FILE__), '/fixtures/bid_history.json')), symbolize_names: true)
        )

        bid_prices = ec_util.best_spot_bid_price('m3.medium')
        expect(bid_prices).to match_array([
                                            ['us-west-1a', 0.08244842404174188],
                                            ['us-west-1c', 0.07917263606261282]
                                          ])
      end

      it 'should return a list of bid recommendations (paginate)' do
        ec2_client.stub_responses(
          :describe_spot_price_history,
          [
            {
              next_token: '1123123',
              spot_price_history: [
                {
                  availability_zone: 'us-west-1a',
                  instance_type: 'm3.medium',
                  product_description: 'Linux/UNIX (Amazon VPC)',
                  spot_price: '0.080000',
                  timestamp: Time.parse('2014-01-06T04:32:53.000Z')
                }
              ]
            },
            {
              next_token: '',
              spot_price_history: [
                {
                  availability_zone: 'us-west-1a',
                  instance_type: 'm3.medium',
                  product_description: 'Linux/UNIX (Amazon VPC)',
                  spot_price: '0.080000',
                  timestamp: Time.parse('2014-01-06T04:32:53.000Z')
                }
              ]
            }
          ]
        )

        expect { ec_util.best_spot_bid_price('m3.medium') }.not_to raise_error
      end
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
