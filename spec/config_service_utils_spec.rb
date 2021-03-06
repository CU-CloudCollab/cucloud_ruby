require 'spec_helper'

describe Cucloud::ConfigServiceUtils do
  let(:cs_client) do
    Aws::ConfigService::Client.new(stub_responses: true)
  end

  let(:cs_util) do
    Cucloud::ConfigServiceUtils.new cs_client
  end

  it '.new default optional should be successful' do
    expect(Cucloud::ConfigServiceUtils.new).to be_a_kind_of(Cucloud::ConfigServiceUtils)
  end

  it 'dependency injection asg_client should be successful' do
    expect(Cucloud::ConfigServiceUtils.new(cs_client)).to be_a_kind_of(Cucloud::ConfigServiceUtils)
  end

  it '.new should throw Cucloud::ConfigServiceUtils::UnsupportedRegionError when using unsupported region' do
    Cucloud.region = 'us-west-1'
    expect { Cucloud::ConfigServiceUtils.new }.to raise_error(Cucloud::ConfigServiceUtils::UnsupportedRegionError)
    Cucloud.region = Cucloud::DEFAULT_REGION # set it back to default so the rest of our tests pass!
  end

  it 'get_available_regions class method call should be successful' do
    expect(Cucloud::ConfigServiceUtils.get_available_regions.class.to_s).to eq 'Array'
    expect(Cucloud::ConfigServiceUtils.get_available_regions.length).to eq 5
  end

  context 'while describe_config_rules is stubbed out with a 2-rule response' do
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
            description: 'test-rule-1 description',
            scope: {
              compliance_resource_types: ['test-rule-2 resource 2'],
              tag_key: 'test-rule-2-tag-key',
              tag_value: 'test-rule-2-tag-value',
              compliance_resource_id: 'test-rule-2-compliance-id'
            },
            source: { # required
              owner: 'AWS',
              source_identifier: 'SOMETHING_ELSE',
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

    describe '#get_config_rules' do
      it 'should return without an error' do
        expect { cs_util.get_config_rules }.not_to raise_error
      end

      it 'should return a 2 element array' do
        expect(cs_util.get_config_rules.length).to eq 2
      end
    end

    describe '#get_config_rule_by_name' do
      it 'should return without an error' do
        expect { cs_util.get_config_rule_by_name('test-rule-1') }.not_to raise_error
      end

      it 'should return expected rule (first)' do
        expect(cs_util.get_config_rule_by_name('test-rule-1').config_rule_arn).to eq 'test-rule-1-arn'
      end
    end
  end

  context 'while describe_config_rules is stubbed out active cloudtrail rule' do
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
          }
        ]
      )
    end

    describe '#rule_active?' do
      it 'should return without an error' do
        expect { cs_util.rule_active?(cs_util.get_config_rule_by_name('test-rule-1')) }.not_to raise_error
      end

      it 'should return true' do
        expect(cs_util.rule_active?(cs_util.get_config_rule_by_name('test-rule-1'))).to eq true
      end
    end
  end

  context 'while describe_config_rules is stubbed out NON-active NON-cloudtrail rule' do
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
              source_identifier: 'OTHER_RULE',
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
            config_rule_state: 'DELETING'
          }
        ]
      )
    end

    describe '#rule_active?' do
      it 'should return without an error' do
        expect { cs_util.rule_active?(cs_util.get_config_rule_by_name('test-rule-1')) }.not_to raise_error
      end

      it 'should return false' do
        expect(cs_util.rule_active?(cs_util.get_config_rule_by_name('test-rule-1'))).to eq false
      end
    end
  end

  context 'while describe_config_rule_evaluation_status is stubbed out as running 23 hours ago' do
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
              source_identifier: 'OTHER_RULE',
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
          }
        ]
      )

      cs_client.stub_responses(
        :describe_config_rule_evaluation_status,
        config_rules_evaluation_status: [
          {
            config_rule_name: 'test-rule-1',
            config_rule_arn: 'test-rule-arn-1',
            config_rule_id: 'test-rule-id-1',
            last_successful_invocation_time: Time.now - (60 * 60 * 23), # w/in last day
            last_failed_invocation_time: Time.now - (60 * 60 * 23),
            last_successful_evaluation_time: Time.now - (60 * 60 * 23),
            last_failed_evaluation_time: Time.now - (60 * 60 * 23),
            first_activated_time: Time.now - (60 * 60 * 23),
            last_error_code: 'test-error-code',
            last_error_message: 'test-error-message',
            first_evaluation_started: true
          }
        ]
      )
    end

    describe '#get_rule_evaluation_status_by_name' do
      it 'should return without an error' do
        expect { cs_util.get_rule_evaluation_status_by_name('test-rule-1') }.not_to raise_error
      end

      it 'should return rule w/ expected values' do
        expect(cs_util.get_rule_evaluation_status_by_name('test-rule-1').config_rule_name).to eq 'test-rule-1'
      end
    end

    describe '#hours_since_last_run' do
      it 'should return without an error' do
        expect { cs_util.hours_since_last_run(cs_util.get_config_rule_by_name('test-rule-1')) }.not_to raise_error
      end

      it 'should return 23' do
        expect(cs_util.hours_since_last_run(cs_util.get_config_rule_by_name('test-rule-1'))).to eq 23
      end
    end
  end

  context 'while describe_config_rule_evaluation_status is stubbed out with nil last invocation' do
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
              source_identifier: 'OTHER_RULE',
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
          }
        ]
      )

      cs_client.stub_responses(
        :describe_config_rule_evaluation_status,
        config_rules_evaluation_status: [
          {
            config_rule_name: 'test-rule-1',
            config_rule_arn: 'test-rule-arn-1',
            config_rule_id: 'test-rule-id-1',
            last_successful_invocation_time: nil,
            last_failed_invocation_time: Time.now - (60 * 60 * 24),
            last_successful_evaluation_time: Time.now - (60 * 60 * 24),
            last_failed_evaluation_time: Time.now - (60 * 60 * 24),
            first_activated_time: Time.now - (60 * 60 * 24),
            last_error_code: 'test-error-code',
            last_error_message: 'test-error-message',
            first_evaluation_started: true
          }
        ]
      )
    end

    describe '#hours_since_last_run' do
      it 'should return without an error' do
        expect { cs_util.hours_since_last_run(cs_util.get_config_rule_by_name('test-rule-1')) }.not_to raise_error
      end

      it 'should return nil' do
        expect(cs_util.hours_since_last_run(cs_util.get_config_rule_by_name('test-rule-1')).nil?).to eq true
      end
    end
  end

  context 'while get_compliance_details_by_config_rule is stubbed out with compliant response' do
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
              source_identifier: 'OTHER_RULE',
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
          }
        ]
      )

      cs_client.stub_responses(
        :get_compliance_details_by_config_rule,
        evaluation_results: [
          {
            evaluation_result_identifier: {
              evaluation_result_qualifier: {
                config_rule_name: 'test-rule-1',
                resource_type: 'test-resource-type',
                resource_id: 'test-resource-id'
              },
              ordering_timestamp: Time.now - (60 * 60 * 24)
            },
            compliance_type: 'COMPLIANT',
            result_recorded_time: Time.now - (60 * 60 * 24),
            config_rule_invoked_time: Time.now - (60 * 60 * 24),
            annotation: 'test-annotation',
            result_token: 'test-token'
          }
        ]
      )
    end

    describe '#get_rule_compliance_by_name' do
      it 'should return without an error' do
        expect { cs_util.get_rule_compliance_by_name('test-rule-1') }.not_to raise_error
      end

      it 'should return rule w/ expected values' do
        expect(cs_util.get_rule_compliance_by_name('test-rule-1').compliance_type).to eq 'COMPLIANT'
      end
    end

    describe '#rule_compliant?' do
      it 'should return without an error' do
        expect { cs_util.rule_compliant?(cs_util.get_config_rule_by_name('test-rule-1')) }.not_to raise_error
      end

      it 'should return true' do
        expect(cs_util.rule_compliant?(cs_util.get_config_rule_by_name('test-rule-1'))).to eq true
      end
    end
  end

  context 'while describe_configuration_recorder_status is stubbed out and recorder is active' do
    before do
      cs_client.stub_responses(
        :describe_configuration_recorder_status,
        configuration_recorders_status: [
          {
            recording: true,
            last_status: 'SUCCESS'
          }
        ]
      )
    end

    describe '#recorder_active?' do
      it 'should return ture' do
        expect(cs_util.recorder_active?).to be true
      end
    end
  end

  context 'while describe_configuration_recorder_status is stubbed out and recorder is active' do
    before do
      cs_client.stub_responses(
        :describe_configuration_recorder_status,
        configuration_recorders_status: [
          {
            recording: false,
            last_status: 'SUCCESS'
          }
        ]
      )
    end

    describe '#recorder_active?' do
      it 'should return ture' do
        expect(cs_util.recorder_active?).to be false
      end
    end
  end

  context 'while get_compliance_details_by_config_rule is stubbed out with NON-compliant response' do
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
              source_identifier: 'OTHER_RULE',
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
          }
        ]
      )

      cs_client.stub_responses(
        :get_compliance_details_by_config_rule,
        evaluation_results: [
          {
            evaluation_result_identifier: {
              evaluation_result_qualifier: {
                config_rule_name: 'test-rule-1',
                resource_type: 'test-resource-type',
                resource_id: 'test-resource-id'
              },
              ordering_timestamp: Time.now - (60 * 60 * 24)
            },
            compliance_type: 'NON-COMPLIANT',
            result_recorded_time: Time.now - (60 * 60 * 24),
            config_rule_invoked_time: Time.now - (60 * 60 * 24),
            annotation: 'test-annotation',
            result_token: 'test-token'
          }
        ]
      )
    end

    describe '#rule_compliant?' do
      it 'should return without an error' do
        expect { cs_util.rule_compliant?(cs_util.get_config_rule_by_name('test-rule-1')) }.not_to raise_error
      end

      it 'should return false' do
        expect(cs_util.rule_compliant?(cs_util.get_config_rule_by_name('test-rule-1'))).to eq false
      end
    end
  end
end
