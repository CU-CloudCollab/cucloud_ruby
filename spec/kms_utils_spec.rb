require 'spec_helper'

describe Cucloud::KmsUtils do
  let(:kms_client) do
    Aws::KMS::Client.new(stub_responses: true)
  end

  let(:kms_util) do
    Cucloud::KmsUtils.new kms_client
  end

  let(:key_id) do
    'arn:aws:kms:us-east-1:095493758574:key/5e4c428f-6446-4004-b0ee-0a19710b110f'
  end

  let(:plaintext) do
    'plain text'
  end

  let(:ciphertext) do
    Base64.strict_encode64(plaintext)
  end

  it '.new default optional should be successful' do
    expect(Cucloud::KmsUtils.new).to be_a_kind_of(Cucloud::KmsUtils)
  end

  it '.new dependency injection of kms_client should be successful' do
    expect(Cucloud::KmsUtils.new(kms_client)).to be_a_kind_of(Cucloud::KmsUtils)
  end

  describe '#decrypt' do
    it 'should raise an error when ciphertext is nil' do
      expect { kms_util.decrypt(nil) }.to raise_error(NoMethodError)
    end

    it 'should raise an error when ciphertext is not valid Base64 string encoded' do
      expect { kms_util.decrypt(plaintext) }.to raise_error(ArgumentError)
    end

    before do
      kms_client.stub_responses(
        :decrypt,
        plaintext: plaintext,
        key_id: key_id)
    end

    it 'should return plaintext when an encrypted value is passed' do
      expect(kms_util.decrypt(ciphertext)).to eq(plaintext)
    end
  end

  describe '#encrypt' do

    it 'should raise an error when plaintext is nil' do
      expect { kms_util.encrypt(nil) }.to raise_error(ArgumentError)
    end

  end

  context 'while KmsUtils has no kms_key_id set' do
    it 'should return nil ksm_key_id' do
      expect(kms_util.kms_key_id).to be_nil
    end

    describe '#encrypt' do
      it 'should raise an error when no kms_key_id is passed' do
        expect { kms_util.encrypt('plaintext') }.to raise_error(ArgumentError)
      end

      it 'should not raise an error when plaintext is empty string' do
        expect { kms_util.encrypt('', key_id) }.not_to raise_error
      end

      before do
        kms_client.stub_responses(
          :encrypt,
          ciphertext_blob: plaintext,
          key_id: key_id)
      end

      it 'should return ciphertext when a kms_key_id is passed' do
        expect(kms_util.encrypt(plaintext, key_id)).to eq(ciphertext)
      end
    end
  end

  context 'while KmsUtils has a kms_key_id set' do
    before do
      kms_util.kms_key_id = key_id
    end

    it 'should return the kms_key_id' do
      expect(kms_util.kms_key_id).to eq key_id
    end

    describe '#encrypt' do
      it 'should not raise an error when no kms_key_id is passed' do
        expect { kms_util.encrypt('plaintext') }.not_to raise_error
      end

      it 'should not raise an error when plaintext is empty string' do
        expect { kms_util.encrypt('') }.not_to raise_error
      end

      before do
        kms_client.stub_responses(
          :encrypt,
          ciphertext_blob: plaintext,
          key_id: key_id)
      end

      it 'should return ciphertext when no kms_key_id is passed' do
        expect(kms_util.encrypt(plaintext, key_id)).to eq(ciphertext)
      end

      it 'should return ciphertext when a kms_key_id is passed' do
        expect(kms_util.encrypt(plaintext, key_id)).to eq(ciphertext)
      end
    end
  end


end
