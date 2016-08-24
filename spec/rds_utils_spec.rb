require 'spec_helper'

describe Cucloud::RdsUtils do
  let(:rds_client) do
    Aws::RDS::Client.new(stub_responses: true)
  end

  let(:rds_utils) do
    Cucloud::RdsUtils.new rds_client
  end

  it '.new default optional should be successful' do
    expect(Cucloud::RdsUtils.new).to be_a_kind_of(Cucloud::RdsUtils)
  end

  it 'dependency injection iam_client should be successful' do
    expect(Cucloud::RdsUtils.new(rds_client)).to be_a_kind_of(Cucloud::RdsUtils)
  end
end
