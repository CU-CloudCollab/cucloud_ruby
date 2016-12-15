require 'spec_helper'

describe Cucloud::KmsUtils do
  let(:kms_client) do
    Aws::IAM::Client.new(stub_responses: true)
  end

  let(:kms_util) do
    Cucloud::KmsUtils.new kms_client
  end

  let(:key_id) do
    'arn:aws:kms:us-east-1:095493758574:key/5e4c428f-6446-4004-b0ee-0a19710b110f'
  end

  it '.new default optional should be successful' do
    expect(Cucloud::KmsUtils.new).to be_a_kind_of(Cucloud::KmsUtils)
  end

  it 'dependency injection of kms_client should be successful' do
    expect(Cucloud::KmsUtils.new(kms_client)).to be_a_kind_of(Cucloud::KmsUtils)
  end

  it 'dependency injection of kms_client and kms_key_id should be successful' do
    let(:util) { Cucloud::KmsUtils.new(kms_client, key_id) }
    expect(util).to be_a_kind_of(Cucloud::KmsUtils)
    export(util.kms_key_id).to eq key_id
  end

  # context 'while IAM list_account_aliases is stubbed with aliased account' do
  #   before do
  #     kms_client.stub_responses(
  #       :list_account_aliases,
  #       is_truncated: false,
  #       account_aliases: ['test-alias']
  #     )
  #   end
  #
  #   describe '#get_account_alias' do
  #     it 'should return without an error' do
  #       expect { kms_util.get_account_alias }.not_to raise_error
  #     end
  #
  #     it 'should return expected value' do
  #       expect(kms_util.get_account_alias).to eq 'test-alias'
  #     end
  #
  #     it 'should return type String' do
  #       expect(kms_util.get_account_alias.class.to_s).to eq 'String'
  #     end
  #   end
  # end
end
