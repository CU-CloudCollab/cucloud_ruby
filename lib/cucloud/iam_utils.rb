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

      audit_array = []
      audit_criteria.each do |check|
        case check[:operator]
        when 'EQ'
          audit_array << {
            key: check[:key],
            passes: policy_hash[check[:key].to_sym].nil? ? false : policy_hash[check[:key].to_sym] == check[:value]
          }
        when 'LTE'
          audit_array << {
            key: check[:key],
            passes: policy_hash[check[:key].to_sym].nil? ? false : policy_hash[check[:key].to_sym] <= check[:value]
          }
        when 'GTE'
          audit_array << {
            key: check[:key],
            passes: policy_hash[check[:key].to_sym].nil? ? false : policy_hash[check[:key].to_sym] >= check[:value]
          }
        else
          raise UnknownComparisonOperatorError.new, "Unknown operator #{check[:operator]}"
        end
      end

      audit_array
    end

    # Get SAML providers configured for this account
    # @return [Array<Hash>] Array of hashes in form { arn: <String>, metadata: <String> }
    def get_saml_providers
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Client.html#list_saml_providers-instance_method
      # returns https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Types/SAMLProviderListEntry.html
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Client.html#get_saml_provider-instance_method

      provider_array = []
      @iam.list_saml_providers.saml_provider_list.each do |provider|
        provider_array << {
          arn: provider.arn,
          saml_metadata_document: @iam.get_saml_provider(saml_provider_arn: provider.arn).saml_metadata_document
        }
      end

      provider_array
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
      user_array = []
      @iam.list_users.users.each do |user|
        user_array << {
          base_data: user, # https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Types/User.html
          has_password: user_has_password?(user.user_name)
        }
      end
      user_array
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
      keys = []
      @iam.list_access_keys(user_name: user_name).access_key_metadata.each do |key|
        keys << {
          base_data: key,
          active: key.status == 'Active',
          days_old: (Time.now - key.create_date).to_i / (24 * 60 * 60)
        }
      end

      keys
    end

    # Get active access keys on account that are older than specified age (in days)
    # @param [Integer] Days old
    # @return [Array<Hash>]
    def get_active_keys_older_than_n_days(n)
      keys = []
      get_users.each do |user|
        keys << get_user_access_keys(user[:base_data].user_name).select { |k| k[:days_old] > n && k[:active] }
      end

      keys.flatten
    end
  end
end
