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

  let(:testcases1) do
    [
      nil, '', 1, 'string', {}, []
    ]
  end

  let(:testcases2) do
    [
      { 'key1' => 'value1' },
      { key1: 'value1' },
      { 'key1' => 'value1' },
      { 'key1_decrypted' => 'value1' },
      { 'key1' => %w('value1 value2') },
      { 'level1' => { 'key1' => 'value1' } },
      { 'level1' => { 'level2' => { 'key1' => 'value1' } } },
      { 'level1' => { 'level2' => { 'level3' => { 'key1' => 'value1' } } } },
      { 'key9' => 'value9',
        'level1' => { 'key9' => 'value9', 'key1' => 'value1' } },
      { 'key9' => 'value9',
        'level1' => { 'key9' => 'value9',
                      'level2' => { 'key9' => 'value9', 'key1' => 'value1' } } },
      { 'key9' => 'value9',
        'level1' => { 'key9' => 'value9',
                      'level2' => { 'key9' => 'value9',
                                    'level3' => { 'key1' => 'value1' } } } },
      ['value1'],
      %w('value1 value2'),
      ['value1', %w('value2 value3')],
      [{ 'key1' => 'value1' }],
      [{ 'key1' => 'value1' }, { 'key2' => 'value2' }]
    ]
  end

  it '.new default optional should be successful' do
    expect(Cucloud::KmsUtils.new).to be_a_kind_of(Cucloud::KmsUtils)
  end

  it '.new dependency injection of kms_client should be successful' do
    expect(Cucloud::KmsUtils.new(kms_client)).to be_a_kind_of(Cucloud::KmsUtils)
  end

  describe '#decrypt' do
    it 'should return nil when ciphertext is nil' do
      expect(kms_util.decrypt(nil)).to be_nil
    end

    it 'should return emptry string when ciphertext is emptry string' do
      expect(kms_util.decrypt('')).to eq('')
    end

    it 'should raise an error when ciphertext is not valid Base64 string encoded' do
      expect { kms_util.decrypt(plaintext) }.to raise_error(ArgumentError)
    end

    before do
      kms_client.stub_responses(
        :decrypt,
        plaintext: plaintext,
        key_id: key_id
      )
    end

    it 'should return plaintext when an encrypted value is passed' do
      expect(kms_util.decrypt(ciphertext)).to eq(plaintext)
    end
  end

  describe '#encrypt' do
    it 'should return nil when plaintext is nil' do
      expect(kms_util.encrypt(nil)).to be_nil
    end

    it 'should return empty string when plaintext is empty string' do
      expect(kms_util.encrypt('')).to eq('')
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
          key_id: key_id
        )
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
          key_id: key_id
        )
      end

      it 'should return ciphertext when no kms_key_id is passed' do
        expect(kms_util.encrypt(plaintext, key_id)).to eq(ciphertext)
      end

      it 'should return ciphertext when a kms_key_id is passed' do
        expect(kms_util.encrypt(plaintext, key_id)).to eq(ciphertext)
      end
    end

    describe '#encrypt_struct' do
      it 'should return degenerate objects without change' do
        testcases1.each do |item|
          expect(kms_util.encrypt_struct(item)).to eq(item)
        end
      end

      it 'should return objects not containing a hash key with suffix _decrypted without change' do
        testcases2.each do |item|
          expect(kms_util.encrypt_struct(item)).to eq(item)
        end
      end

      before do
        kms_client.stub_responses(
          :encrypt,
          ciphertext_blob: plaintext,
          key_id: key_id
        )
      end

      let(:testcases3) do
        [
          { input: { 'key1_decrypted' => plaintext }, output: { 'key1_encrypted' => ciphertext } },
          { input: { key1_decrypted: plaintext }, output: { key1_encrypted: ciphertext } },
          { input: { key1_encrypted: ciphertext }, output: { key1_encrypted: ciphertext } }
        ]
      end

      it 'should encrypt values for keys with suffix _decrypted' do
        testcases3.each do |testcase|
          expect(kms_util.encrypt_struct(testcase[:input])).to include(testcase[:output])
        end
      end

      let(:testcases4) do
        [
          { input: { level1: { key1_decrypted: plaintext } }, output: { level1: { key1_encrypted: ciphertext } } },
          { input: { level1: { level2: { key1_decrypted: plaintext } } },
            output: { level1: { level2: { key1_encrypted: ciphertext } } } },
          { input: { level1: 'nothing', key1_decrypted: plaintext },
            output: { level1: 'nothing', key1_encrypted: ciphertext } },
          { input: ['nothing', { level1: { key1_decrypted: plaintext } }],
            output: { level1: { key1_encrypted: ciphertext } } }
        ]
      end
      it 'should encrypt values for keys with suffix _decrypted and maintain original object structure' do
        testcases4.each do |testcase|
          expect(kms_util.encrypt_struct(testcase[:input])).to include(testcase[:output])
        end
      end

      let(:testcases5) do
        [
          { input: { key1_decrypted: plaintext }, output: :key_decrypted },
          { input: { key1_encrypted: ciphertext }, output: :key_decrypted }
        ]
      end
      it 'should encrypt values for keys with suffix _decrypted and remove original key' do
        testcases5.each do |testcase|
          expect(kms_util.encrypt_struct(testcase[:input])).not_to include(testcase[:output])
        end
      end
    end

    describe '#decrypt_struct' do
      it 'should return degenerate objects without change' do
        testcases1.each do |item|
          expect(kms_util.decrypt_struct(item)).to eq(item)
        end
      end

      it 'should return objects not containing a hash key with suffix _encrypted without change' do
        testcases2.each do |item|
          expect(kms_util.decrypt_struct(item)).to eq(item)
        end
      end

      before do
        kms_client.stub_responses(
          :decrypt,
          plaintext: plaintext,
          key_id: key_id
        )
      end

      let(:testcases3) do
        [
          { input: { 'key1_encrypted' => ciphertext }, output: { 'key1_decrypted' => plaintext } },
          { input: { key1_encrypted: ciphertext }, output: { key1_decrypted: plaintext } },
          { input: { key1_decrypted: plaintext }, output: { key1_decrypted: plaintext } }
        ]
      end
      it 'should decrypt values for keys with suffix _encrypted' do
        testcases3.each do |testcase|
          expect(kms_util.decrypt_struct(testcase[:input])).to include(testcase[:output])
        end
      end

      let(:testcases4) do
        [
          { input: { level1: { key1_encrypted: ciphertext } },
            output: { level1: { key1_decrypted: plaintext, key1_encrypted: ciphertext } } },
          { input: { level1: { level2: { key1_encrypted: ciphertext } } },
            output: { level1: { level2: { key1_decrypted: plaintext, key1_encrypted: ciphertext } } } },
          { input: { level1: 'nothing', key1_encrypted: ciphertext },
            output: { level1: 'nothing', key1_decrypted: plaintext, key1_encrypted: ciphertext } },
          { input: ['nothing', { level1: { key1_encrypted: ciphertext } }],
            output: { level1: { key1_decrypted: plaintext, key1_encrypted: ciphertext } } }
        ]
      end
      it 'should decrypt values for keys with suffix _encrypted and add to original object structure' do
        testcases4.each do |testcase|
          expect(kms_util.decrypt_struct(testcase[:input])).to include(testcase[:output])
        end
      end
    end
  end
end
