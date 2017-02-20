module Cucloud
  # Utilities library for interacting with KMS.
  class KmsUtils
    class MissingKmsKey < StandardError
    end

    ENCRYPTED_SUFFIX = '_encrypted'.freeze
    DECRYPTED_SUFFIX = '_decrypted'.freeze

    attr_accessor :kms_key_id

    # Initialize the class optionally providing an existing Aws::KMS::Client
    # @param kms_client [Aws::KMS::Client] optional
    def initialize(kms_client = Aws::KMS::Client.new)
      @kms = kms_client
    end

    # Decrypt the given Base64-strict-encoded ciphertext.
    # @param ciphertext [String]  encrypted and Base64 strict encoded string
    # @return [String] decrypted string (i.e. plaintext)
    def decrypt(ciphertext)
      return nil if ciphertext.nil?
      return '' if ciphertext.empty?
      @kms.decrypt(ciphertext_blob: Base64.strict_decode64(ciphertext)).plaintext
    end

    # Encrypt the given plaintext. Uses provided the KMS key provided,
    # or the KMS key configured at initialization if none is provided.
    # @param plaintext [String] plaintext string to be encrypted
    # @param key_id [String] KMS key id to use for encryption (optional)
    # @return [String] Encrypted and Base64 strict encoded ciphertext
    def encrypt(plaintext, key_id = @kms_key_id)
      return nil if plaintext.nil?
      return '' if plaintext.empty?
      Base64.strict_encode64(@kms.encrypt(key_id: key_id, plaintext: plaintext).ciphertext_blob)
    end

    # Process the given structure and decrypt the values of any
    # attributes with names suffixed by "\_encrypted". For each such encrypted
    # atttribute-value pair, adds a new attribute with suffix "_decrypted"
    # and value consisting of the plaintext (i.e. decrypted value)
    # of the encrypted value.
    # @example
    #   decrypt_struct({ x_encrypted: <encrypted_value> }) =>
    #     { x_encrypted: <encrypted_value>, x_decrypted: <plaintext> }
    #   decrypt_struct([{ x_encrypted: <encrypted_value> } ]) =>
    #     [{ x_encrypted: <encrypted_value>, x_decrypted: <plaintext> }]
    # @param main_node the structure (Hash, Array) to decrypt
    # @return a copy of the structure with additional atttribute-value pairs for the decrypted values
    def decrypt_struct(main_node)
      return nil if main_node.nil?
      return main_node if main_node.is_a?(String)
      if main_node.is_a?(Hash)
        new_hash = {}
        main_node.each_pair do |key, value|
          if key_to_decrypt?(key)
            plaintext = decrypt(value)
            new_hash[decrypted_key_label(key)] = plaintext
            new_hash[key] = value
          else
            result = decrypt_struct(value)
            new_hash[key] = result
          end
        end
        return new_hash
      elsif main_node.is_a?(Array)
        new_array = []
        main_node.each do |element|
          result = decrypt_struct(element)
          new_array << result
        end
        return new_array
      else
        return main_node
      end
    end

    # Process the given structure and encrypt the values of any attributes
    # with names suffixed by "_decrypted". For each such plaintext
    # atttribute-value pair, adds a new attribute with suffix "\_encrypted"
    # and value consisting of the encrypted value. The "_decrypted"
    # atttribute-value pair is removed from the structure. Uses the
    # provided the KMS key provided,
    # or the KMS key configured at initialization if none is provided.
    # @example
    #   encrypt_struct({ x_decrypted: <plaintext> }) =>
    #     { x_encrypted: <encrypted_value> }
    #   encrypt_struct([{ x_decrypted: <plaintext> }]) =>
    #     [{ x_encrypted: <encrypted_value> }]
    # @param main_node the structure (Hash, Array) to encrypt_struct
    # @param key_id [String] KMS key id to use for encryption (optional)
    # @return a copy of the structure with decrypted atttribute-value pairs replaced by encrypted atttribute-value pairs
    def encrypt_struct(main_node, key_id = @kms_key_id)
      return nil if main_node.nil?
      if main_node.is_a?(Hash)
        new_hash = {}
        remove_keys = []
        main_node.each_pair do |key, value|
          if key_to_encrypt?(key)
            ciphertext = encrypt(value, key_id)
            new_hash[encrypted_key_label(key)] = ciphertext
            remove_keys << key
          else
            result = encrypt_struct(value, key_id)
            new_hash[key] = result
          end
        end
        main_node.merge!(new_hash)
        main_node.delete_if do |key, _|
          remove_keys.include?(key)
        end
        return main_node
      elsif main_node.is_a?(Array)
        main_node.map do |element|
          encrypt_struct(element, key_id)
        end
      else
        return main_node
      end
    end

    # Read a JSON file and encrypt JSON attributes within it.
    # JSON attributes having name suffixed by "_decrypted" will be encrypted and added to the
    # JSON structure. The original "_decrypted" atttribute-value pairs are removed from the
    # returned JSON and replaced with "\_encrypted" versions.
    # @param filename the name of the source JSON file
    # @param key_id [String] KMS key id to use for encryption (optional)
    # @return JSON content of the file with encrypted atttribute-value pairs
    def encrypt_json_file(filename, key_id = @kms_key_id)
      require 'json'
      encrypt_json(JSON.parse(File.read(filename)), key_id)
    end

    # Encrypt attribute values within the JSON structure.
    # JSON attributes having name suffixed by "_decrypted" will be encrypted and added to the
    # JSON structure. The original "_decrypted" atttribute-value pairs are removed from the
    # returned JSON and replaced with "\_encrypted" versions.
    #
    # This function is particularly useful for encrypting custom JSON passed
    # to OpsWorks stacks or recipes.
    #
    # If the JSON structure contains a top-level attribute named "kem_key_arn",
    # that KMS key is used for encryption.
    # @param json [JSON] JSON structure to be encrypted
    # @param key_id [String] KMS key id to use for encryption (optional)
    # @return JSON structure with decrypted atttribute-value pairs replaced by encrypted atttribute-value pairs
    def encrypt_json(json, key_id = @kms_key_id)
      # expect kms_key_arn at top level of file and
      # use it if no key_id is passed in
      if key_id.nil?
        raise(
          MissingKmsKey,
          'No KMS key ID provided. Expecting \'kms_key_arn\' as top-level key in JSON'
        ) unless json.key?('kms_key_arn')
        key_id = json['kms_key_arn']
      end
      encrypt_struct(json, key_id)
    end

    # Read a JSON file and decrypt JSON attributes within it.
    # JSON attributes having name suffixed by "\_encrypted" will be decrypted and added to the
    # JSON structure. The original "\_encrypted" atttribute-value pairs are left intact in the
    # returned JSON.
    # @param filename the name of the source JSON file
    # @return JSON content of the file with decrypted atttribute-value pairs added
    def decrypt_json_file(filename)
      require 'json'
      decrypt_json(JSON.parse(File.read(filename)))
    end

    # Decrypt attributes within the provided JSON.
    # JSON attributes having name suffixed by "\_encrypted" will be decrypted and added to the
    # JSON structure. The original "\_encrypted" atttribute-value pairs are left intact in the
    # returned JSON.
    #
    # This function is particularly useful for encrypting custom JSON passed
    # to OpsWorks stacks or recipes.
    # @param json [JSON] the JSON structure to decrypt
    # @return JSON with decrypted atttribute-value pairs added
    def decrypt_json(json)
      decrypt_struct(json)
    end

    private

    def key_to_decrypt?(key)
      key.to_s.end_with?(ENCRYPTED_SUFFIX)
    end

    def key_to_encrypt?(key)
      key.to_s.end_with?(DECRYPTED_SUFFIX)
    end

    def encrypted_key_label(key)
      if key.is_a?(Symbol)
        key.to_s.sub(DECRYPTED_SUFFIX, ENCRYPTED_SUFFIX).to_sym
      else
        key.sub(DECRYPTED_SUFFIX, ENCRYPTED_SUFFIX)
      end
    end

    def decrypted_key_label(key)
      if key.is_a?(Symbol)
        key.to_s.sub(ENCRYPTED_SUFFIX, DECRYPTED_SUFFIX).to_sym
      else
        key.sub(ENCRYPTED_SUFFIX, DECRYPTED_SUFFIX)
      end
    end
  end
end
