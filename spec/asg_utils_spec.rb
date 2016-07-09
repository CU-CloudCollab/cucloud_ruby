require 'spec_helper'

describe Cucloud::AsgUtils do
  let(:asg_client) do
    Aws::AutoScaling::Client.new(stub_responses: true)
  end

  let(:asg_util) do
    Cucloud::AsgUtils.new asg_client
  end

  it '.new default optional should be successful' do
    expect(Cucloud::AsgUtils.new).to be_a_kind_of(Cucloud::AsgUtils)
  end

  it 'dependency injection asg_client should be successful' do
    expect(Cucloud::AsgUtils.new(asg_client)).to be_a_kind_of(Cucloud::AsgUtils)
  end

  context 'while asg is stubbed out with matching search result' do
    before do
      asg_client.stub_responses(
        :describe_auto_scaling_groups,
        next_token: nil,
        auto_scaling_groups: [{
          auto_scaling_group_name: 'test-group',
          auto_scaling_group_arn: 'arn:test-group',
          launch_configuration_name: 'test-launch-config',
          min_size: 0,
          max_size: 10,
          desired_capacity: 5,
          default_cooldown: 300,
          availability_zones: ['us-east-1a'],
          health_check_type: 'test',
          created_time: Time.new(2016, 7, 9, 13, 30, 0)
        }]
      )
    end

    it "'get_asg_by_name' should return without an error" do
      expect { asg_util.get_asg_by_name('test-group') }.not_to raise_error
    end

    it "'get_asg_by_name' should return first result" do
      expect(asg_util.get_asg_by_name('test-group').auto_scaling_group_name.to_s).to eq 'test-group'
    end

    it "'get_asg_by_name' should return type Aws::AutoScaling::Types::AutoScalingGroup" do
      expect(asg_util.get_asg_by_name('test-group').class.to_s).to eq 'Aws::AutoScaling::Types::AutoScalingGroup'
    end
  end

  context 'while asg is stubbed out with no search result (not found)' do
    before do
      asg_client.stub_responses(
        :describe_auto_scaling_groups,
        next_token: nil,
        auto_scaling_groups: []
      )
    end

    it "'get_asg_by_name' should return without an error" do
      expect { asg_util.get_asg_by_name('test-group') }.not_to raise_error
    end

    it "'get_asg_by_name' should return nil" do
      expect(asg_util.get_asg_by_name('test-group').nil?).to eq true
    end
  end
end
