require 'spec_helper'
require 'date'

describe Cucloud::IamUtils do
  let(:iam_client) do
    Aws::IAM::Client.new(stub_responses: true)
  end

  let(:iam_util) do
    Cucloud::IamUtils.new iam_client
  end

  it '.new default optional should be successful' do
    expect(Cucloud::IamUtils.new).to be_a_kind_of(Cucloud::IamUtils)
  end

  it 'dependency injection iam_client should be successful' do
    expect(Cucloud::IamUtils.new(iam_client)).to be_a_kind_of(Cucloud::IamUtils)
  end

  context 'while IAM list_account_aliases is stubbed with aliased account' do
    before do
      iam_client.stub_responses(
        :list_account_aliases,
        is_truncated: false,
        account_aliases: ['test-alias']
      )
    end

    it "'get_account_alias' should return without an error" do
      expect { iam_util.get_account_alias }.not_to raise_error
    end

    it "'get_account_alias' should return expected value" do
      expect(iam_util.get_account_alias).to eq 'test-alias'
    end

    it "'get_asg_by_name' should return type String" do
      expect(iam_util.get_account_alias.class.to_s).to eq 'String'
    end
  end

  context 'while IAM list_account_aliases is stubbed with an unaliased account' do
    before do
      iam_client.stub_responses(
        :list_account_aliases,
        is_truncated: false,
        account_aliases: []
      )
    end

    it "'get_account_alias' should return without an error" do
      expect { iam_util.get_account_alias }.not_to raise_error
    end

    it "'get_account_alias' should return nil" do
      expect(iam_util.get_account_alias.nil?).to eq true
    end
  end

  context 'while IAM get_account_summary is stubbed with a response' do
    before do
      iam_client.stub_responses(
        :get_account_summary,
        summary_map: {
          'test_key_1' => 1,
          'test_key_2' => 2
        }
      )
    end

    it "'get_account_summary' should return without an error" do
      expect { iam_util.get_account_summary }.not_to raise_error
    end

    it "'get_account_summary' return hash should have expected keys/values" do
      expect(iam_util.get_account_summary['test_key_3'].nil? ||
             iam_util.get_account_summary['test_key_2'].nil?).to eq true
    end
  end

  context 'while IAM get_account_summary is stubbed with false responses to keys of interest' do
    before do
      iam_client.stub_responses(
        :get_account_summary,
        summary_map: {
          'AccountAccessKeysPresent' => 0,
          'AccountMFAEnabled' => 0,
          'Providers' => 0
        }
      )
    end

    it "'get_account_summary' should return without an error" do
      expect { iam_util.get_account_summary }.not_to raise_error
    end

    it "'root_user_has_api_key?' should return without an error" do
      expect { iam_util.root_user_has_api_key? }.not_to raise_error
    end

    it "'root_user_has_api_key?' should return false" do
      expect(iam_util.root_user_has_api_key?).to eq false
    end

    it "'root_user_mfa_enabled?' should return without an error" do
      expect { iam_util.root_user_mfa_enabled? }.not_to raise_error
    end

    it "'root_user_mfa_enabled?' should return false" do
      expect(iam_util.root_user_mfa_enabled?).to eq false
    end

    it "'multiple_providers_configured?' should return without an error" do
      expect { iam_util.multiple_providers_configured? }.not_to raise_error
    end

    it "'multiple_providers_configured?' should return false" do
      expect(iam_util.multiple_providers_configured?).to eq false
    end
  end

  context 'while IAM get_account_summary is stubbed with true responses to keys of interest' do
    before do
      iam_client.stub_responses(
        :get_account_summary,
        summary_map: {
          'AccountAccessKeysPresent' => 1,
          'AccountMFAEnabled' => 1,
          'Providers' => 2 # check is for > 1 provider
        }
      )
    end

    it "'get_account_summary' should return without an error" do
      expect { iam_util.get_account_summary }.not_to raise_error
    end

    it "'root_user_has_api_key?' should return without an error" do
      expect { iam_util.root_user_has_api_key? }.not_to raise_error
    end

    it "'root_user_has_api_key?' should return true" do
      expect(iam_util.root_user_has_api_key?).to eq true
    end

    it "'root_user_mfa_enabled?' should return without an error" do
      expect { iam_util.root_user_mfa_enabled? }.not_to raise_error
    end

    it "'root_user_mfa_enabled?' should return true" do
      expect(iam_util.root_user_mfa_enabled?).to eq true
    end

    it "'multiple_providers_configured?' should return without an error" do
      expect { iam_util.multiple_providers_configured? }.not_to raise_error
    end

    it "'multiple_providers_configured?' should return true" do
      expect(iam_util.multiple_providers_configured?).to eq true
    end
  end

  context 'while IAM list_saml_providers is stubbed out with zero providers' do
    before do
      iam_client.stub_responses(
        :list_saml_providers,
        saml_provider_list: []
      )
    end

    it "'get_saml_providers' should return without an error" do
      expect { iam_util.get_saml_providers }.not_to raise_error
    end

    it "'get_saml_providers should return empty array" do
      puts iam_util.get_saml_providers
      expect(iam_util.get_saml_providers.empty?).to eq true
    end

    it "'cornell_provider_configured?' should return without an error" do
      expect { iam_util.cornell_provider_configured? }.not_to raise_error
    end

    it "'cornell_provider_configured?' should return false" do
      expect(iam_util.cornell_provider_configured?).to eq false
    end
  end

  context 'while IAM list_saml_providers is stubbed out with one Cornell provider' do
    before do
      iam_client.stub_responses(
        :list_saml_providers,
        saml_provider_list: [
          arn: 'test-arn',
          valid_until: Time.new(2018, 7, 9, 13, 30, 0),
          create_date: Time.new(2016, 7, 9, 13, 30, 0)
        ]
      )

      # disable line-length check for mock saml response
      # rubocop:disable Metrics/LineLength
      iam_client.stub_responses(
        :get_saml_provider,
        valid_until: Time.new(2018, 7, 9, 13, 30, 0),
        create_date: Time.new(2016, 7, 9, 13, 30, 0),
        saml_metadata_document: "<KeyDescriptor><ds:KeyInfo><ds:X509Data><ds:X509Certificate>MIIDSDCCAjCgAwIBAgIVAOZ8NfBem6sHcI7F39sYmD/JG4YDMA0GCSqGSIb3DQEB\nBQUAMCIxIDAeBgNVBAMTF3NoaWJpZHAuY2l0LmNvcm5lbGwuZWR1MB4XDTA5MTEy\nMzE4NTI0NFoXDTI5MTEyMzE4NTI0NFowIjEgMB4GA1UEAxMXc2hpYmlkcC5jaXQu\nY29ybmVsbC5lZHUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCTURo9\n90uuODo/5ju3GZThcT67K3RXW69jwlBwfn3png75Dhyw9Xa50RFv0EbdfrojH1P1\n9LyfCjubfsm9Z7FYkVWSVdPSvQ0BXx7zQxdTpE9137qj740tMJr7Wi+iWdkyBQS/\nbCNhuLHeNQor6NXZoBgX8HvLy4sCUb/4v7vbp90HkmP3FzJRDevzgr6PVNqWwNqp\ntZ0vQHSF5D3iBNbxq3csfRGQQyVi729XuWMSqEjPhhkf1UjVcJ3/cG8tWbRKw+W+\nOIm71k+99kOgg7IvygndzzaGDVhDFMyiGZ4njMzEJT67sEq0pMuuwLMlLE/86mSv\nuGwO2Qacb1ckzjodAgMBAAGjdTBzMFIGA1UdEQRLMEmCF3NoaWJpZHAuY2l0LmNv\ncm5lbGwuZWR1hi5odHRwczovL3NoaWJpZHAuY2l0LmNvcm5lbGwuZWR1L2lkcC9z\naGliYm9sZXRoMB0GA1UdDgQWBBSQgitoP2/rJMDepS1sFgM35xw19zANBgkqhkiG\n9w0BAQUFAAOCAQEAaFrLOGqMsbX1YlseO+SM3JKfgfjBBL5TP86qqiCuq9a1J6B7\nYv+XYLmZBy04EfV0L7HjYX5aGIWLDtz9YAis4g3xTPWe1/bjdltUq5seRuksJjyb\nprGI2oAv/ShPBOyrkadectHzvu5K6CL7AxNTWCSXswtfdsuxcKo65tO5TRO1hWlr\n7Pq2F+Oj2hOvcwC0vOOjlYNe9yRE9DjJAzv4rrZUg71R3IEKNjfOF80LYPAFD2Sp\np36uB6TmSYl1nBmS5LgWF4EpEuODPSmy4sIV6jl1otuyI/An2dOcNqcgu7tYEXLX\nC8N6DXggDWPtPRdpk96UW45huvXudpZenrcd7A==</ds:X509Certificate></ds:X509Data></ds:KeyInfo></KeyDescriptor>"
      )
      # rubocop:enable Metrics/LineLength
    end

    it "'get_saml_providers' should return without an error" do
      expect { iam_util.get_saml_providers }.not_to raise_error
    end

    it "'get_saml_providers' should return non-empty array" do
      expect(iam_util.get_saml_providers.empty?).to eq false
    end

    it "'cornell_provider_configured?' should return without an error" do
      expect { iam_util.cornell_provider_configured? }.not_to raise_error
    end

    it "'cornell_provider_configured?' should return true" do
      expect(iam_util.cornell_provider_configured?).to eq true
    end
  end

  context 'while IAM list_saml_providers is stubbed without with one non-Cornell provider' do
    before do
      iam_client.stub_responses(
        :list_saml_providers,
        saml_provider_list: [
          arn: 'test-arn',
          valid_until: Time.new(2018, 7, 9, 13, 30, 0),
          create_date: Time.new(2016, 7, 9, 13, 30, 0)
        ]
      )

      # rubocop:disable Metrics/LineLength
      iam_client.stub_responses(
        :get_saml_provider,
        valid_until: Time.new(2018, 7, 9, 13, 30, 0),
        create_date: Time.new(2016, 7, 9, 13, 30, 0),
        saml_metadata_document: '<KeyDescriptor><ds:KeyInfo><ds:X509Data><ds:X509Certificate></ds:X509Certificate></ds:X509Data></ds:KeyInfo></KeyDescriptor>'
      )
      # rubocop:enable Metrics/LineLength
    end

    it "'get_saml_providers' should return without an error" do
      expect { iam_util.get_saml_providers }.not_to raise_error
    end

    it "'get_saml_providers' should return non-empty array" do
      expect(iam_util.get_saml_providers.empty?).to eq false
    end

    it "'cornell_provider_configured?' should return without an error" do
      expect { iam_util.cornell_provider_configured? }.not_to raise_error
    end

    it "'cornell_provider_configured?' should return false" do
      expect(iam_util.cornell_provider_configured?).to eq false
    end
  end

  context 'while IAM list_users is stubbed with empty return' do
    before do
      iam_client.stub_responses(
        :list_users,
        users: []
      )
    end

    it "'get_users' should return without an error" do
      expect { iam_util.get_users }.not_to raise_error
    end

    it "'get_users' should return empty array" do
      expect(iam_util.get_users.empty?).to eq true
    end
  end

  context 'while IAM login profile lookup is stubbed with a profile that exists' do
    before do
      iam_client.stub_responses(
        :get_login_profile,
        login_profile: {
          user_name: 'test-user',
          create_date: Time.new(2016, 7, 9, 13, 30, 0),
          password_reset_required: false
        }
      )
    end

    it "'user_has_password?' should return true" do
      expect(iam_util.user_has_password?('test-user')).to eq true
    end
  end

  context 'while IAM login profile lookup is stubbed to throw Aws::IAM::Errors::NoSuchEntity' do
    before do
      iam_client.stub_responses(
        :get_login_profile,
        'NoSuchEntity'
      )
    end

    it "'user_has_password?' should return false" do
      expect(iam_util.user_has_password?('test-user')).to eq false
    end
  end

  context 'while IAM list_users is stubbed with test users' do
    before do
      iam_client.stub_responses(
        :list_users,
        users: [
          {
            path: 'test-path-1',
            user_name: 'test-user-1',
            user_id: 'test-id-1',
            arn: 'test-arn-1',
            password_last_used: Time.new(2016, 7, 9, 13, 30, 0),
            create_date: Time.new(2016, 7, 9, 13, 30, 0)
          },
          {
            path: 'test-path-2',
            user_name: 'test-user-2',
            user_id: 'test-id-2',
            arn: 'test-arn-2',
            password_last_used: Time.new(2016, 7, 9, 13, 30, 0),
            create_date: Time.new(2016, 7, 9, 13, 30, 0)
          }
        ]
      )
    end

    context 'while IAM login profile lookup is stubbed with a profile that exists' do
      before do
        iam_client.stub_responses(
          :get_login_profile,
          login_profile: {
            user_name: 'test-user',
            create_date: Time.new(2016, 7, 9, 13, 30, 0),
            password_reset_required: false
          }
        )
      end

      it "'get_users' should return without an error" do
        expect { iam_util.get_users }.not_to raise_error
      end

      it "'get_users' should return non-empty array" do
        expect(iam_util.get_users.empty?).to eq false
      end

      it "'get_users' should return user struct values for each array element" do
        expect(iam_util.get_users[0][:base_data].path).to eq 'test-path-1'
        expect(iam_util.get_users[0][:base_data].user_name).to eq 'test-user-1'
        expect(iam_util.get_users[0][:base_data].user_id).to eq 'test-id-1'
        expect(iam_util.get_users[1][:base_data].path).to eq 'test-path-2'
        expect(iam_util.get_users[1][:base_data].user_name).to eq 'test-user-2'
        expect(iam_util.get_users[1][:base_data].user_id).to eq 'test-id-2'
      end

      it "'get_users' has_password key should be true" do
        expect(iam_util.get_users[0][:has_password]).to eq true
        expect(iam_util.get_users[1][:has_password]).to eq true
      end
    end

    context 'while IAM login profile lookup is stubbed to throw Aws::IAM::Errors::NoSuchEntity' do
      before do
        iam_client.stub_responses(
          :get_login_profile,
          'NoSuchEntity'
        )
      end

      it "'get_users' should return without an error" do
        expect { iam_util.get_users }.not_to raise_error
      end

      it "'get_users' should return non-empty array" do
        expect(iam_util.get_users.empty?).to eq false
      end

      it "'get_users' should return user struct values for each array element" do
        expect(iam_util.get_users[0][:base_data].path).to eq 'test-path-1'
        expect(iam_util.get_users[0][:base_data].user_name).to eq 'test-user-1'
        expect(iam_util.get_users[0][:base_data].user_id).to eq 'test-id-1'
        expect(iam_util.get_users[1][:base_data].path).to eq 'test-path-2'
        expect(iam_util.get_users[1][:base_data].user_name).to eq 'test-user-2'
        expect(iam_util.get_users[1][:base_data].user_id).to eq 'test-id-2'
      end

      it "'get_users' has_password key should be false" do
        expect(iam_util.get_users[0][:has_password]).to eq false
        expect(iam_util.get_users[1][:has_password]).to eq false
      end
    end
  end

  context 'while IAM list_access_keys is stubbed with no matching user' do
    before do
      iam_client.stub_responses(
        :list_access_keys,
        access_key_metadata: []
      )
    end

    it "'get_user_access_keys' should return without an error" do
      expect { iam_util.get_user_access_keys('test-user') }.not_to raise_error
    end

    it "'get_user_access_keys' should return empty array" do
      expect(iam_util.get_user_access_keys('test-user').empty?).to eq true
    end
  end

  context 'while IAM list_access_keys is stubbed with matching user and test keys' do
    before do
      iam_client.stub_responses(
        :list_users,
        users: [
          {
            path: 'test-path-1',
            user_name: 'test-user-1',
            user_id: 'test-id-1',
            arn: 'test-arn-1',
            password_last_used: Time.new(2016, 7, 9, 13, 30, 0),
            create_date: Time.new(2016, 7, 9, 13, 30, 0)
          },
          {
            path: 'test-path-2',
            user_name: 'test-user-2',
            user_id: 'test-id-2',
            arn: 'test-arn-2',
            password_last_used: Time.new(2016, 7, 9, 13, 30, 0),
            create_date: Time.new(2016, 7, 9, 13, 30, 0)
          }

        ]
      )

      iam_client.stub_responses(
        :list_access_keys,
        access_key_metadata: [
          {
            user_name: 'test-user',
            access_key_id: 'test-key-1',
            status: 'Active',
            create_date: Time.now - (60 * 60 * 24 * 60) # 60 days ago
          },
          {
            user_name: 'test-user',
            access_key_id: 'test-key-2',
            status: 'Inactive',
            create_date: Time.now - (60 * 60 * 24 * 90) # 90 days ago
          },
          {
            user_name: 'test-user',
            access_key_id: 'test-key-3',
            status: 'Active',
            create_date: Time.now - (60 * 60 * 24 * 120) # 120 days ago
          },
          {
            user_name: 'test-user',
            access_key_id: 'test-key-4',
            status: 'Active',
            create_date: Time.now - (60 * 60 * 24 * 150) # 150 days ago
          }
        ]
      )
    end

    it "'get_user_access_keys' should return without an error" do
      expect { iam_util.get_user_access_keys('test-user') }.not_to raise_error
    end

    it "'get_user_access_keys' should return empty array" do
      expect(iam_util.get_user_access_keys('test-user').empty?).to eq false
    end

    it "'get_user_access_keys' should have original respone data in base_data key" do
      expect(iam_util.get_user_access_keys('test-user')[0][:base_data].user_name).to eq 'test-user'
      expect(iam_util.get_user_access_keys('test-user')[0][:base_data].access_key_id).to eq 'test-key-1'
      expect(iam_util.get_user_access_keys('test-user')[0][:base_data].status).to eq 'Active'
      expect(iam_util.get_user_access_keys('test-user')[1][:base_data].user_name).to eq 'test-user'
      expect(iam_util.get_user_access_keys('test-user')[1][:base_data].access_key_id).to eq 'test-key-2'
      expect(iam_util.get_user_access_keys('test-user')[1][:base_data].status).to eq 'Inactive'
      expect(iam_util.get_user_access_keys('test-user')[2][:base_data].user_name).to eq 'test-user'
      expect(iam_util.get_user_access_keys('test-user')[2][:base_data].access_key_id).to eq 'test-key-3'
      expect(iam_util.get_user_access_keys('test-user')[2][:base_data].status).to eq 'Active'
      expect(iam_util.get_user_access_keys('test-user')[3][:base_data].user_name).to eq 'test-user'
      expect(iam_util.get_user_access_keys('test-user')[3][:base_data].access_key_id).to eq 'test-key-4'
      expect(iam_util.get_user_access_keys('test-user')[3][:base_data].status).to eq 'Active'
    end

    it "'get_user_access_keys' key age should calculate correctly" do
      expect(iam_util.get_user_access_keys('test-user')[0][:days_old]).to eq 60
      expect(iam_util.get_user_access_keys('test-user')[1][:days_old]).to eq 90
      expect(iam_util.get_user_access_keys('test-user')[2][:days_old]).to eq 120
      expect(iam_util.get_user_access_keys('test-user')[3][:days_old]).to eq 150
    end

    it "'get_user_access_keys' active boolean should calculate correctly" do
      expect(iam_util.get_user_access_keys('test-user')[0][:active]).to eq true
      expect(iam_util.get_user_access_keys('test-user')[1][:active]).to eq false
      expect(iam_util.get_user_access_keys('test-user')[2][:active]).to eq true
      expect(iam_util.get_user_access_keys('test-user')[3][:active]).to eq true
    end

    it "'get_user_access_keys' active boolean should calculate correctly" do
      expect(iam_util.get_user_access_keys('test-user')[0][:active]).to eq true
      expect(iam_util.get_user_access_keys('test-user')[1][:active]).to eq false
      expect(iam_util.get_user_access_keys('test-user')[2][:active]).to eq true
      expect(iam_util.get_user_access_keys('test-user')[3][:active]).to eq true
    end

    it "'get_active_keys_older_than_n_days' should return without an error" do
      expect { iam_util.get_active_keys_older_than_n_days(80) }.not_to raise_error
    end

    it "'get_active_keys_older_than_n_days' return 4 keys over 90 days old" do
      expect(iam_util.get_active_keys_older_than_n_days(80).length).to eq 4
    end
  end

  context 'while IAM get_account_password_policy is stubbed out' do
    before do
      iam_client.stub_responses(
        :get_account_password_policy,
        password_policy: {
          minimum_password_length: 20,
          require_symbols: false,
          require_numbers: true,
          require_uppercase_characters: true,
          require_lowercase_characters: false,
          allow_users_to_change_password: true,
          expire_passwords: true,
          max_password_age: 20,
          password_reuse_prevention: 1,
          hard_expiry: true
        }
      )
    end

    it "'get_account_password_policy' should return without an error" do
      expect { iam_util.get_account_password_policy }.not_to raise_error
    end

    it "'get_account_password_policy' should have values of return" do
      expect(iam_util.get_account_password_policy.minimum_password_length).to eq 20
      expect(iam_util.get_account_password_policy.require_symbols).to eq false
      expect(iam_util.get_account_password_policy.require_numbers).to eq true
      expect(iam_util.get_account_password_policy.require_uppercase_characters).to eq true
    end

    it "'audit_password_policy' should return without an error" do
      expect { iam_util.audit_password_policy }.not_to raise_error
    end

    it "'audit_password_policy' should return expected results to example test" do
      audit_example = [
        {
          key: 'minimum_password_length',
          operator: 'GT',
          value: 15
        },
        {
          operator: 'EQ',
          key: 'require_symbols',
          value: true
        },
        {
          operator: 'EQ',
          key: 'require_numbers',
          value: true
        },
        {
          operator: 'EQ',
          key: 'require_uppercase_characters',
          value: true
        },
        {
          operator: 'EQ',
          key: 'require_lowercase_characters',
          value: true
        },
        {
          operator: 'EQ',
          key: 'allow_users_to_change_password',
          value: true
        },
        {
          operator: 'EQ',
          key: 'expire_passwords',
          value: true
        },
        {
          operator: 'LT',
          key: 'max_password_age',
          value: 10
        },
        {
          operator: 'LT',
          key: 'password_reuse_prevention',
          value: 3
        },
        {
          operator: 'EQ',
          key: 'hard_expiry',
          value: true
        }
      ]

      expect(iam_util.audit_password_policy(audit_example)[0][:passes]).to eq true
      expect(iam_util.audit_password_policy(audit_example)[1][:passes]).to eq false
      expect(iam_util.audit_password_policy(audit_example)[2][:passes]).to eq true
      expect(iam_util.audit_password_policy(audit_example)[3][:passes]).to eq true
      expect(iam_util.audit_password_policy(audit_example)[4][:passes]).to eq false
      expect(iam_util.audit_password_policy(audit_example)[5][:passes]).to eq true
      expect(iam_util.audit_password_policy(audit_example)[6][:passes]).to eq true
      expect(iam_util.audit_password_policy(audit_example)[7][:passes]).to eq false
      expect(iam_util.audit_password_policy(audit_example)[8][:passes]).to eq true
      expect(iam_util.audit_password_policy(audit_example)[9][:passes]).to eq true
    end

    it "'audit_password_policy' should throw AuditKeyNotFoundError exception on unknown check key" do
      test_audit = [{
        operator: 'EQ',
        key: 'hard_expiryyyy',
        value: true
      }]

      expect { iam_util.audit_password_policy(test_audit) }.to raise_error(Cucloud::IamUtils::AuditKeyNotFoundError)
    end

    it "'audit_password_policy' should throw UnknownComparisonOperatorError exception on unknown operator" do
      test_audit = [{
        operator: 'EQQ',
        key: 'hard_expiry',
        value: true
      }]

      expect do
        iam_util.audit_password_policy(test_audit)
      end.to raise_error(Cucloud::IamUtils::UnknownComparisonOperatorError)
    end
  end
end
