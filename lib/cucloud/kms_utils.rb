module Cucloud
  # Utilities library for interacting with KMS
  class KmsUtils

    attr_accessor :kms_key_id

    def initialize(kms_client = Aws::KMS::Client.new, key_id = nil)
      @kms = kms_client
      @kms_key_id = key_id
    end

    # Decrypt the given Base64-strict-encoded ciphertext.
    # @param ciphertext [String]  encrypted and Base64 strict encoded string
    # @return plaintext [String] descrypted string
    def decrypt(ciphertext)
      @kms.decrypt(ciphertext_blob: Base64.strict_decode64(ciphertext)).plaintext
    end

    # Encrypt the given plaintext. Uses provided the KMS key provided,
    # or the KMS key configured at initialization if none is provided.
    # @param plaintext [String] plaintext string to be encrypted
    # @param key_id [String] KMS key id to use for encryption (optional)
    # @return [String] Encrypted and Base64 strict encoded ciphertext
    def encrypt(plaintext, key_id = @kms_key_id)
      Base64.strict_encode64(@kms.encrypt(key_id: key_id, plaintext: plaintext).ciphertext_blob)
    end
  end
end
