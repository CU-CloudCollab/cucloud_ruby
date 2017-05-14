module Cucloud
  # Utilities library for interacting with IAM
  class IamUtils
    # Define some error classes
    class UnknownComparisonOperatorError < StandardError
    end

    def initialize(iam_client = Aws::IAM::Client.new)
      @iam = iam_client
    end

    # Get the alias set for this account if it exists
    # @return [String] Account alias (nil if not set)
    def get_account_alias
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Client.html#list_account_aliases-instance_method
      # https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html
      # Per user guide: Account can have only one alias

      @iam.list_account_aliases.account_aliases[0]
    end

    # Get report about IAM entity usage and quotas in this account
    # @return [Hash<String,Integer>] A hash of key value pairs containing information about IAM entity usage and quotas.
    def get_account_summary
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Client.html#get_account_summary-instance_method
      # return https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Types/GetAccountSummaryResponse.html#summary_map-instance_method
      @iam.get_account_summary.summary_map
    end

    # Does this account's root user have any API keys?
    # @return [Boolean]
    def root_user_has_api_key?
      get_account_summary['AccountAccessKeysPresent'] > 0
    end

    # Does this account's root user have MFA enabled?
    # @return [Boolean]
    def root_user_mfa_enabled?
      get_account_summary['AccountMFAEnabled'] > 0
    end

    # Does this account have multiple identity providers configured?
    # @return [Boolean]
    def multiple_providers_configured?
      get_account_summary['Providers'] > 1
    end

    # Get password policy for this account
    # @return [Aws::IAM::Types::PasswordPolicy]
    def get_account_password_policy
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Client.html#get_account_password_policy-instance_method
      @iam.get_account_password_policy.password_policy
    end

    # Check password policy against an options hash of audit criteria
    #
    # Policy format - Array of checks
    # example input: [{ key: "minimum_password_length", operator: "GT", value: 15 }]
    # example output: [{ key: "minimum_password_length", passes: true }]
    # @param [Array<Hash>] Policy against which to audit
    # @return [Array<Hash>] Results of each audit check
    def audit_password_policy(audit_criteria = [])
      policy_hash = get_account_password_policy.to_h

      audit_criteria.map do |check|
        case check[:operator]
        when 'EQ'
          {
            key: check[:key],
            passes: policy_hash[check[:key].to_sym].nil? ? false : policy_hash[check[:key].to_sym] == check[:value]
          }
        when 'LTE'
          {
            key: check[:key],
            passes: policy_hash[check[:key].to_sym].nil? ? false : policy_hash[check[:key].to_sym] <= check[:value]
          }
        when 'GTE'
          {
            key: check[:key],
            passes: policy_hash[check[:key].to_sym].nil? ? false : policy_hash[check[:key].to_sym] >= check[:value]
          }
        else
          raise UnknownComparisonOperatorError.new, "Unknown operator #{check[:operator]}"
        end
      end
    end

    # Get SAML providers configured for this account
    # @return [Array<Hash>] Array of hashes in form { arn: <String>, metadata: <String> }
    def get_saml_providers
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Client.html#list_saml_providers-instance_method
      # returns https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Types/SAMLProviderListEntry.html
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Client.html#get_saml_provider-instance_method

      @iam.list_saml_providers.saml_provider_list.map do |provider|
        {
          arn: provider.arn,
          saml_metadata_document: @iam.get_saml_provider(saml_provider_arn: provider.arn).saml_metadata_document
        }
      end
    end

    # Is the Cornell SAML Identity Provider configured on this account?
    # @return [Boolean]
    def cornell_provider_configured?
      get_saml_providers.select { |provider| provider[:saml_metadata_document].include? CORNELL_SAML_X509 }.any?
    end

    # Get users that are configured on this account
    # @return [Array<Hash>] Array of user hashes - base user type + added lookups for convenience
    def get_users
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Client.html#list_users-instance_method
      @iam.list_users.users.map do |user|
        {
          base_data: user, # https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Types/User.html
          has_password: user_has_password?(user.user_name)
        }
      end
    end

    # Does this user have a password configured?
    # @param [String] Username
    # @return [Boolean]
    def user_has_password?(user_name)
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Client.html#get_login_profile-instance_method
      password = true

      begin
        @iam.get_login_profile(user_name: user_name)
      rescue Aws::IAM::Errors::NoSuchEntity
        password = false
      end

      password
    end

    # Get access keys for user
    # @param [String] Username
    # @return [Array<Hash>] Array of key hashes - base key data + helper calculations for key age and active/inactive
    def get_user_access_keys(user_name)
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Client.html#list_access_keys-instance_method

      @iam.list_access_keys(user_name: user_name).access_key_metadata.map do |key|
        {
          base_data: key,
          active: key.status == 'Active',
          days_old: (Time.now - key.create_date).to_i / (24 * 60 * 60)
        }
      end
    end

    # Get active access keys on account that are older than specified age (in days)
    # @param [Integer] Days old
    # @return [Array<Hash>]
    def get_active_keys_older_than_n_days(n)
      get_users.map do |user|
        get_user_access_keys(user[:base_data].user_name).select { |k| k[:days_old] > n && k[:active] }
      end.flatten
    end

    # Gets the ARN for a given certificate
    # @param [String] cert_name The name of the certificate
    # @param [String] The ARN for the certificate
    # @raise [ArgumentError] If the provided certificate name is nil
    def get_cert_arn(cert_name)
      raise ArgumentError, '"cert_name" may not be nil' if cert_name.nil?

      cert = @iam.get_server_certificate(server_certificate_name: cert_name)
      cert.server_certificate.server_certificate_metadata.arn
    end

    # Given an IAM credential rotate it
    # @param creds_to_rotate [Hash<string>] IAM access_key_id and and secret_access_key to rotate
    # @return [Hash<string>] new IAM access_key_id and and secret_access_key
    def rotate_iam_credntial(creds_to_rotate)
      # create the iam client and get the last time the key was used
      iam = Aws::IAM::Client.new(
        region: region_name,
        credentials: Aws::Credentials.new(creds_to_rotate['aws_access_key_id'],
                                          creds_to_rotate['aws_secret_access_key'])
      )

      # now grab the user name form the response
      resp = iam.get_access_key_last_used(access_key_id: creds_to_rotate['aws_access_key_id'])
      user = resp.user_name

      # create and store new keys
      resp = iam.create_access_key(user_name: user)
      new_access_key_id = resp.access_key.access_key_id
      new_secret_access_key = resp.access_key.secret_access_key

      # give time for the new credentials to become active
      sleep 15

      # use new credentials
      iam = Aws::IAM::Client.new(
        region: region_name,
        credentials: Aws::Credentials.new(new_access_key_id,
                                          new_secret_access_key)
      )

      # Delete the old keys with the new key
      iam.delete_access_key(user_name: user,
                            access_key_id: creds_to_rotate['aws_access_key_id'])

      { aws_access_key_id: new_access_key_id, aws_secret_access_key: new_secret_access_key }
    end
  end
end
