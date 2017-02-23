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
      status: 'available',
      db_snapshot_identifier: 'snap1',
      snapshot_create_time: Time.new(2004),
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

  context 'while describe_db_instances is returns an instand not found error' do
    before do
      rds_client.stub_responses(
        :describe_db_instances,
        Aws::RDS::Errors::DBInstanceNotFound.new('test', 'test')
      )
      rds_client.stub_responses(
        :restore_db_instance_from_db_snapshot,
        db_instance: {
          db_instance_identifier: 'testDb'
        }
      )
      rds_client.stub_responses(
        :describe_db_snapshots,
        db_snapshots: [
          mock_snapshot
        ]
      )
    end

    describe '#does_db_exist?' do
      it 'should not exist' do
        expect(rds_utils.does_db_exist?('bogus')).to eq false
      end
    end

    describe '#delete_db_instance' do
      it 'should raise error with non existant db' do
        expect { rds_utils.delete_db_instance('testDb') }.to raise_error Aws::RDS::Errors::DBInstanceNotFound
      end
    end

    describe '#restore_db' do
      it 'should not raise error with non existant db' do
        expect { rds_utils.restore_db('testDb', 'prodDb') }.not_to raise_error
      end

      it 'should not raise error with non existant db, specifying snapshot id' do
        expect { rds_utils.restore_db('testDb', nil, db_snapshot_identifier: 'snap1') }.not_to raise_error
      end
    end
  end

  context 'while describe_db_instances is returns an instand not found error' do
    before do
      rds_client.stub_responses(
        :delete_db_instance,
        db_instance: {
          db_instance_identifier: 'testDb'
        }
      )
      rds_client.stub_responses(
        :describe_db_instances,
        db_instances: [
          db_instance_status: 'deleted'
        ]
      )
    end

    describe '#delete_db_instance?' do
      it 'should not raise error' do
        expect { rds_utils.delete_db_instance('testDb') }.not_to raise_error
      end
    end

    describe '#delete_db_instance?' do
      it 'should not exist' do
        expect { rds_utils.delete_db_instance('testDb', '111111') }.not_to raise_error
      end
    end
  end

  context 'while describe_db_snapshots is mocked with multipe availble snapshots' do
    before do
      rds_client.stub_responses(
        :describe_db_snapshots,
        db_snapshots: [
          mock_snapshot,
          mock_snapshot.merge(db_snapshot_identifier: 'snap2', snapshot_create_time: Time.new(2008))
        ]
      )
      rds_client.stub_responses(
        :describe_db_instances,
        db_instances: [
          {
            db_instance_identifier: 'testDb',
            instance_create_time: Time.new('2016-09-26 17:53:05 UTC')
          }
        ]
      )
    end

    describe '#find_latest_snapshot' do
      it 'should return a snapshot identifier' do
        expect(rds_utils.find_latest_snapshot(db_instance.id)).to eq 'snap2'
      end
    end
  end

  context 'while describe_db_instances is mocked with a response' do
    before do
      rds_client.stub_responses(
        :describe_db_instances,
        db_instances: [
          {
            db_instance_identifier: 'testDb',
            instance_create_time: Time.new('2016-09-26 17:53:05 UTC')
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

      describe '#does_db_exist?' do
        it ' should exist' do
          expect(rds_utils.does_db_exist?('testDb')).to eq true
        end
      end

      describe '#restore_db' do
        it 'should not raise error with non existant db' do
          expect { rds_utils.restore_db('testDb', 'prodDb') }.not_to raise_error
        end
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

        describe '#find_latest_snapshot' do
          it 'should return a nil since there are no available snapshots' do
            expect(rds_utils.find_latest_snapshot(db_instance.id)).to be_nil
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
