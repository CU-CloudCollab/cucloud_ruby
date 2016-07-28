require 'spec_helper'

describe Cucloud::CloudTrailUtils do
  let(:ct_client) do
    Aws::CloudTrail::Client.new(stub_responses: true)
  end

  let(:cs_client) do
    Aws::ConfigService::Client.new(stub_responses: true)
  end

  let(:cs_util) do
    Cucloud::ConfigServiceUtils.new cs_client
  end

  let(:ct_util) do
    Cucloud::CloudTrailUtils.new ct_client, cs_util
  end

  it '.new default optional should be successful' do
    expect(Cucloud::CloudTrailUtils.new).to be_a_kind_of(Cucloud::CloudTrailUtils)
  end

  it 'dependency injection ct_client should be successful' do
    expect(Cucloud::CloudTrailUtils.new(ct_client)).to be_a_kind_of(Cucloud::CloudTrailUtils)
  end

  context 'while describe_trails is stubbed out with global ITSO trail' do
    before do
      ct_client.stub_responses(
        :describe_trails,
        trail_list: [
          {
            name: 'test-trail-1',
            s3_bucket_name: 'test-trail-bucket-1',
            s3_key_prefix: 'test-trail-prefix-1',
            sns_topic_name: 'test-trail-sns-name-1',
            sns_topic_arn: 'test-trail-sns-arn-1',
            include_global_service_events: true,
            is_multi_region_trail: true,
            home_region: 'test-trail-region-1',
            trail_arn: 'arn:aws:cloudtrail:us-east-1:444444444444444:trail/itso',
            log_file_validation_enabled: true,
            cloud_watch_logs_log_group_arn: 'test-trail-cw-group-arn-1',
            cloud_watch_logs_role_arn: 'test-trail-cw-role-arn-1',
            kms_key_id: 'test-trail-kms-key-1'
          }
        ]
      )
    end

    it "'get_cloud_trails' should return without an error" do
      expect { ct_util.get_cloud_trails }.not_to raise_error
    end

    it "'get_cloud_trails' should return a 1 element array" do
      expect(ct_util.get_cloud_trails.length).to eq 1
    end

    it "'get_cloud_trail_by_name' should return without an error" do
      expect { ct_util.get_cloud_trail_by_name('test-trail-1') }.not_to raise_error
    end

    it "'get_cloud_trail_by_name' should return expected trail (first)" do
      expect(ct_util.get_cloud_trail_by_name('test-trail-1').name).to eq 'test-trail-1'
    end

    it "'global_trail?' should return without an error" do
      expect { ct_util.global_trail?(ct_util.get_cloud_trail_by_name('test-trail-1')) }.not_to raise_error
    end

    it "'global_trail?' should return true" do
      expect(ct_util.global_trail?(ct_util.get_cloud_trail_by_name('test-trail-1'))).to eq true
    end

    it "'cornell_itso_trail?' should return without an error" do
      expect { ct_util.cornell_itso_trail?(ct_util.get_cloud_trail_by_name('test-trail-1')) }.not_to raise_error
    end

    it "'cornell_itso_trail?' should return true" do
      expect(ct_util.cornell_itso_trail?(ct_util.get_cloud_trail_by_name('test-trail-1'))).to eq true
    end
  end

  context 'while describe_trails is stubbed out with non-global non-ITSO trail' do
    before do
      ct_client.stub_responses(
        :describe_trails,
        trail_list: [
          {
            name: 'test-trail-1',
            s3_bucket_name: 'test-trail-bucket-1',
            s3_key_prefix: 'test-trail-prefix-1',
            sns_topic_name: 'test-trail-sns-name-1',
            sns_topic_arn: 'test-trail-sns-arn-1',
            include_global_service_events: false,
            is_multi_region_trail: true,
            home_region: 'test-trail-region-1',
            trail_arn: 'arn:aws:cloudtrail:us-east-1:444444444444444:trail/fjdkd',
            log_file_validation_enabled: true,
            cloud_watch_logs_log_group_arn: 'test-trail-cw-group-arn-1',
            cloud_watch_logs_role_arn: 'test-trail-cw-role-arn-1',
            kms_key_id: 'test-trail-kms-key-1'
          }
        ]
      )
    end

    it "'global_trail?' should return without an error" do
      expect { ct_util.global_trail?(ct_util.get_cloud_trail_by_name('test-trail-1')) }.not_to raise_error
    end

    it "'global_trail?' should return false" do
      expect(ct_util.global_trail?(ct_util.get_cloud_trail_by_name('test-trail-1'))).to eq false
    end

    it "'cornell_itso_trail?' should return without an error" do
      expect { ct_util.cornell_itso_trail?(ct_util.get_cloud_trail_by_name('test-trail-1')) }.not_to raise_error
    end

    it "'cornell_itso_trail?' should return false" do
      expect(ct_util.cornell_itso_trail?(ct_util.get_cloud_trail_by_name('test-trail-1'))).to eq false
    end
  end

  context 'while get_trail_status is stubbed out with active logging response' do
    before do
      ct_client.stub_responses(
        :describe_trails,
        trail_list: [
          {
            name: 'test-trail-1',
            s3_bucket_name: 'test-trail-bucket-1',
            s3_key_prefix: 'test-trail-prefix-1',
            sns_topic_name: 'test-trail-sns-name-1',
            sns_topic_arn: 'test-trail-sns-arn-1',
            include_global_service_events: true,
            is_multi_region_trail: true,
            home_region: 'test-trail-region-1',
            trail_arn: 'arn:aws:cloudtrail:us-east-1:444444444444444:trail/itso',
            log_file_validation_enabled: true,
            cloud_watch_logs_log_group_arn: 'test-trail-cw-group-arn-1',
            cloud_watch_logs_role_arn: 'test-trail-cw-role-arn-1',
            kms_key_id: 'test-trail-kms-key-1'
          }
        ]
      )

      ct_client.stub_responses(
        :get_trail_status,
        is_logging: true,
        latest_delivery_error: 'test-error-1',
        latest_notification_error: 'test-notification-error-1',
        latest_delivery_time: Time.now - (60 * 60 * 23),
        latest_notification_time: Time.now - (60 * 60 * 23),
        start_logging_time: Time.now - (60 * 60 * 23),
        stop_logging_time: Time.now - (60 * 60 * 23),
        latest_cloud_watch_logs_delivery_error: 'log-delivery-error-1',
        latest_cloud_watch_logs_delivery_time: Time.now - (60 * 60 * 23),
        latest_digest_delivery_time: Time.now - (60 * 60 * 23),
        latest_digest_delivery_error: 'digest-delivery-error-1',
        latest_delivery_attempt_time: 'delivery-attempt-time-str-1',
        latest_notification_attempt_time: 'notification-attempt-time-str-1',
        latest_notification_attempt_succeeded: 'notification-attempt-succeeded-1',
        latest_delivery_attempt_succeeded: 'deliver-attempt-succeeded-1',
        time_logging_started: 'time-logging-started-str-1',
        time_logging_stopped: 'time-logging-stopped-str-1'
      )
    end

    it "'get_trail_status' should return without an error" do
      expect { ct_util.get_trail_status(ct_util.get_cloud_trail_by_name('test-trail-1')) }.not_to raise_error
    end

    it "'get_trail_status' should return expected value" do
      expect(ct_util.get_trail_status(ct_util.get_cloud_trail_by_name('test-trail-1'))
             .latest_delivery_error).to eq 'test-error-1'
    end

    it "'trail_logging_active?' should return without an error" do
      expect { ct_util.trail_logging_active?(ct_util.get_cloud_trail_by_name('test-trail-1')) }.not_to raise_error
    end

    it "'trail_logging_active?' should return true" do
      expect(ct_util.trail_logging_active?(ct_util.get_cloud_trail_by_name('test-trail-1'))).to eq true
    end

    it "'hours_since_last_delivery' should return without an error" do
      expect { ct_util.hours_since_last_delivery(ct_util.get_cloud_trail_by_name('test-trail-1')) }.not_to raise_error
    end

    it "'hours_since_last_delivery' should return 23" do
      expect(ct_util.hours_since_last_delivery(ct_util.get_cloud_trail_by_name('test-trail-1'))).to eq 23
    end
  end

  context 'while get_trail_status is stubbed out with nil latest_delivery_time' do
    before do
      ct_client.stub_responses(
        :describe_trails,
        trail_list: [
          {
            name: 'test-trail-1',
            s3_bucket_name: 'test-trail-bucket-1',
            s3_key_prefix: 'test-trail-prefix-1',
            sns_topic_name: 'test-trail-sns-name-1',
            sns_topic_arn: 'test-trail-sns-arn-1',
            include_global_service_events: true,
            is_multi_region_trail: true,
            home_region: 'test-trail-region-1',
            trail_arn: 'arn:aws:cloudtrail:us-east-1:444444444444444:trail/itso',
            log_file_validation_enabled: true,
            cloud_watch_logs_log_group_arn: 'test-trail-cw-group-arn-1',
            cloud_watch_logs_role_arn: 'test-trail-cw-role-arn-1',
            kms_key_id: 'test-trail-kms-key-1'
          }
        ]
      )

      ct_client.stub_responses(
        :get_trail_status,
        is_logging: true,
        latest_delivery_error: 'test-error-1',
        latest_notification_error: 'test-notification-error-1',
        latest_delivery_time: nil,
        latest_notification_time: Time.now - (60 * 60 * 23),
        start_logging_time: Time.now - (60 * 60 * 23),
        stop_logging_time: Time.now - (60 * 60 * 23),
        latest_cloud_watch_logs_delivery_error: 'log-delivery-error-1',
        latest_cloud_watch_logs_delivery_time: Time.now - (60 * 60 * 23),
        latest_digest_delivery_time: Time.now - (60 * 60 * 23),
        latest_digest_delivery_error: 'digest-delivery-error-1',
        latest_delivery_attempt_time: 'delivery-attempt-time-str-1',
        latest_notification_attempt_time: 'notification-attempt-time-str-1',
        latest_notification_attempt_succeeded: 'notification-attempt-succeeded-1',
        latest_delivery_attempt_succeeded: 'deliver-attempt-succeeded-1',
        time_logging_started: 'time-logging-started-str-1',
        time_logging_stopped: 'time-logging-stopped-str-1'
      )
    end

    it "'trail_logging_active?' should return without an error" do
      expect { ct_util.trail_logging_active?(ct_util.get_cloud_trail_by_name('test-trail-1')) }.not_to raise_error
    end

    it "'trail_logging_active?' should return false" do
      expect(ct_util.trail_logging_active?(ct_util.get_cloud_trail_by_name('test-trail-1'))).to eq false
    end

    it "'hours_since_last_delivery' should return without an error" do
      expect { ct_util.hours_since_last_delivery(ct_util.get_cloud_trail_by_name('test-trail-1')) }.not_to raise_error
    end

    it "'hours_since_last_delivery' should return nil" do
      expect(ct_util.hours_since_last_delivery(ct_util.get_cloud_trail_by_name('test-trail-1')).nil?).to eq true
    end
  end

  context 'while describe_config_rules is stubbed out with one cloudtrail rules' do
    before do
      cs_client.stub_responses(
        :describe_config_rules,
        config_rules: [
          {
            config_rule_name: 'test-rule-1',
            config_rule_arn: 'test-rule-1-arn',
            config_rule_id: 'test-rule-1-id',
            description: 'test-rule-1 description',
            scope: {
              compliance_resource_types: ['test-rule-1 resource 1'],
              tag_key: 'test-rule-1-tag-key',
              tag_value: 'test-rule-1-tag-value',
              compliance_resource_id: 'test-rule-1-compliance-id'
            },
            source: { # required
              owner: 'AWS', # accepts CUSTOM_LAMBDA, AWS
              source_identifier: 'CLOUD_TRAIL_ENABLED',
              source_details: [
                {
                  event_source: 'aws.config', # accepts aws.config
                  message_type: 'ConfigurationItemChangeNotification',
                  maximum_execution_frequency: 'One_Hour'
                }
              ]
            },
            input_parameters: 'test-rule-1-input',
            maximum_execution_frequency: 'One_Hour',
            config_rule_state: 'ACTIVE'
          },
          {
            config_rule_name: 'test-rule-2',
            config_rule_arn: 'test-rule-2-arn',
            config_rule_id: 'test-rule-2-id',
            description: 'test-rule-2 description',
            scope: {
              compliance_resource_types: ['test-rule-2 resource 1'],
              tag_key: 'test-rule-2-tag-key',
              tag_value: 'test-rule-2-tag-value',
              compliance_resource_id: 'test-rule-2-compliance-id'
            },
            source: { # required
              owner: 'AWS', # accepts CUSTOM_LAMBDA, AWS
              source_identifier: 'OTHER_RULE',
              source_details: [
                {
                  event_source: 'aws.config', # accepts aws.config
                  message_type: 'ConfigurationItemChangeNotification',
                  maximum_execution_frequency: 'One_Hour'
                }
              ]
            },
            input_parameters: 'test-rule-2-input',
            maximum_execution_frequency: 'One_Hour',
            config_rule_state: 'ACTIVE'
          }

        ]
      )
    end

    it "'get_config_rules' should return without an error" do
      expect { ct_util.get_config_rules }.not_to raise_error
    end

    it "'get_config_rules' should return array len 1" do
      expect(ct_util.get_config_rules.length).to eq 1
    end

    it "'get_config_rules' should return expected values" do
      expect(ct_util.get_config_rules.first.config_rule_name).to eq 'test-rule-1'
    end
  end

  context 'while describe_config_rules is stubbed without any rules' do
    before do
      cs_client.stub_responses(
        :describe_config_rules,
        config_rules: []
      )
    end

    it "'get_config_rules' should return without an error" do
      expect { ct_util.get_config_rules }.not_to raise_error
    end

    it "'get_config_rules' should return array len 0" do
      expect(ct_util.get_config_rules.length).to eq 0
    end
  end
end
