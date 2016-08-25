require 'spec_helper'

describe Cucloud::RdsUtils do
  let(:rds_client) do
    Aws::RDS::Client.new(stub_responses: true)
  end

  let(:rds_utils) do
    Cucloud::RdsUtils.new rds_client
  end

  let(:db_instance) do
    resource = Aws::RDS::Resource.new(client: rds_client)
    resource.db_instance('testDb')
  end

  let(:mock_snapshot) do
    {
      db_instance_identifier: 'testDb',
      status: 'String',
      db_snapshot_identifier: 'snap1',
      snapshot_create_time: nil,
      engine: 'String',
      allocated_storage: 5,
      port: 3306,
      availability_zone: 'String',
      vpc_id: 'String',
      instance_create_time: nil,
      master_username: 'String',
      engine_version: 'String',
      license_model: 'String',
      snapshot_type: 'String',
      iops: 0,
      option_group_name: 'String',
      percent_progress: 0,
      source_region: 'String',
      source_db_snapshot_identifier: 'String',
      storage_type: 'String',
      tde_credential_arn: 'String',
      encrypted: false,
      kms_key_id: 'String',
      db_snapshot_arn: 'String'
    }
  end

  it '.new default optional should be successful' do
    expect(Cucloud::RdsUtils.new).to be_a_kind_of(Cucloud::RdsUtils)
  end

  it 'dependency injection rds_client should be successful' do
    expect(Cucloud::RdsUtils.new(rds_client)).to be_a_kind_of(Cucloud::RdsUtils)
  end

  context 'while describe_db_instances is mocked with a response' do
    before do
      rds_client.stub_responses(
        :describe_db_instances,
        db_instances: [
          {
            db_instance_identifier: 'testDb'
          }
        ]
      )
    end

    describe '#get_instance' do
      it 'should return without error' do
        expect { rds_utils.get_instance('testDb') }.not_to raise_error
      end

      it 'should return a DBInstance' do
        expect(rds_utils.get_instance('testDb')).to be_a_kind_of(Aws::RDS::DBInstance)
      end

      it 'should return the DBInstance with correct name' do
        expect(rds_utils.get_instance('testDb').db_instance_identifier).to eq 'testDb'
      end
    end

    context 'while create_db_snapshot is mocked with a "creating" snapshot' do
      before do
        rds_client.stub_responses(
          :create_db_snapshot,
          db_snapshot: mock_snapshot.merge(status: 'creating')
        )
      end

      describe '#start_snapshot' do
        it 'should return a snapshot' do
          expect(rds_utils.start_snapshot(db_instance)).to be_a_kind_of(Aws::RDS::DBSnapshot)
        end
      end

      context 'while describe_db_snapshots is mocked with one "creating" snapshot' do
        before do
          rds_client.stub_responses(
            :describe_db_snapshots,
            db_snapshots: [
              mock_snapshot.merge(db_snapshot_identifier: 'snap1', status: 'creating')
            ]
          )
        end

        describe '#create_snapshot_and_wait_until_available' do
          it 'should return nil because a snapshot is pending' do
            expect(rds_utils.create_snapshot_and_wait_until_available(db_instance)).to be_nil
          end
        end
      end

      context 'while describe_db_snapshots is mocked with one "available" snapshot' do
        before do
          rds_client.stub_responses(
            :describe_db_snapshots,
            db_snapshots: [
              mock_snapshot.merge(db_snapshot_identifier: 'snap1', status: 'available')
            ]
          )
        end

        describe '#create_snapshot_and_wait_until_available' do
          it 'should return a snapshot' do
            expect(
              rds_utils.create_snapshot_and_wait_until_available(db_instance)
            ).to be_a_kind_of(Aws::RDS::DBSnapshot)
          end

          it 'should return a snapshot with status "available"' do
            expect(rds_utils.create_snapshot_and_wait_until_available(db_instance).status).to eq('available')
          end
        end
      end
    end
  end

  context 'while describe_db_snapshots is not mocked with any snapshots' do
    describe '#pending_snapshots' do
      it 'should return no snapshots' do
        expect(rds_utils.pending_snapshots(db_instance).count).to eq 0
      end
    end
  end

  context 'while describe_db_snapshots is mocked with two snapshots (one "creating", one "available")' do
    before do
      rds_client.stub_responses(
        :describe_db_snapshots,
        db_snapshots: [
          mock_snapshot.merge(db_snapshot_identifier: 'snap1', status: 'creating'),
          mock_snapshot.merge(db_snapshot_identifier: 'snap2', status: 'available')
        ]
      )
    end

    describe '#pending_snapshots' do
      it 'should return one snapshot' do
        expect(rds_utils.pending_snapshots(db_instance).count).to eq 1
      end
    end
  end

  context 'while describe_db_snapshots is mocked with two "available" snapshots' do
    before do
      rds_client.stub_responses(
        :describe_db_snapshots,
        db_snapshots: [
          mock_snapshot.merge(db_snapshot_identifier: 'snap1', status: 'available'),
          mock_snapshot.merge(db_snapshot_identifier: 'snap2', status: 'available')
        ]
      )
    end

    describe '#pending_snapshots' do
      it 'should return no snapshots' do
        expect(rds_utils.pending_snapshots(db_instance).count).to eq 0
      end
    end
  end

  context 'while describe_db_snapshots is mocked with one "available" snapshot' do
    before do
      rds_client.stub_responses(
        :describe_db_snapshots,
        db_snapshots: [
          mock_snapshot.merge(db_snapshot_identifier: 'snap1', status: 'available')
        ]
      )
    end

    let(:mock_snapshot_resource) do
      resource = Aws::RDS::Resource.new(client: rds_client)
      resource.db_snapshots(
        db_instance_identifier: 'testDb',
        db_snapshot_identifier: 'snap1'
      ).first
    end

    describe '#wait_until_snapshot_available' do
      it 'should return a snapshot' do
        expect(rds_utils.wait_until_snapshot_available(mock_snapshot_resource)).to be_a_kind_of(Aws::RDS::DBSnapshot)
      end

      it 'should return a snapshot with status "available"' do
        expect(rds_utils.wait_until_snapshot_available(mock_snapshot_resource).status).to eq 'available'
      end
    end
  end

  context 'while describe_db_snapshots is mocked with one "creating" snapshot' do
    before do
      rds_client.stub_responses(
        :describe_db_snapshots,
        db_snapshots: [
          mock_snapshot.merge(db_snapshot_identifier: 'snap1', status: 'creating')
        ]
      )
    end

    let(:mock_snapshot_resource) do
      resource = Aws::RDS::Resource.new(client: rds_client)
      resource.db_snapshots(
        db_instance_identifier: 'testDb',
        db_snapshot_identifier: 'snap1'
      ).first
    end

    describe '#wait_until_snapshot_available' do
      it 'should return nil when the snapshot doesn\'t become available before wait timeout' do
        expect(rds_utils.wait_until_snapshot_available(mock_snapshot_resource, 1, 1)).to be_nil
      end
    end
  end
end
