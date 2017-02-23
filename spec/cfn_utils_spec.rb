require 'spec_helper'

describe Cucloud::CfnUtils do
  let(:cfn_client) do
    Aws::CloudFormation::Client.new(stub_responses: true)
  end

  let(:cfn_util) do
    Cucloud::CfnUtils.new cfn_client
  end

  let(:template_json) { StringIO.new('some template') }

  context 'while create_stack returns an error' do
    before do
      cfn_client.stub_responses(
        :create_stack,
        Aws::CloudFormation::Errors::ServiceError.new('', 'test')
      )
      cfn_client.stub_responses(
        :update_stack,
        Aws::CloudFormation::Errors::ServiceError.new('', 'test')
      )
      cfn_client.stub_responses(
        :describe_stack_events,
        stack_events: [
          stack_id: 'stack_id',
          event_id: 'event_id',
          stack_name: 'teststack',
          timestamp: Time.new
        ]
      )
    end

    describe '#create_stack' do
      it 'raises an error' do
        allow(IO).to receive(:read).with('file').and_return('some_data')
        expect { cfn_util.create_stack('teststack', 'file') }.to raise_error Aws::CloudFormation::Errors::ServiceError
      end
    end

    describe '#update_stack' do
      it 'raises an error' do
        allow(IO).to receive(:read).with('file').and_return('some_data')
        expect { cfn_util.update_stack('teststack', 'file') }.to raise_error Aws::CloudFormation::Errors::ServiceError
      end
    end
  end

  context 'while create_stack returns an error' do
    before do
      cfn_client.stub_responses(
        :create_stack,
        stack_id: 'stack_id'
      )
      cfn_client.stub_responses(
        :describe_stacks,
        stacks: [
          stack_id: 'stack_id',
          stack_name: 'teststack',
          creation_time: Time.new,
          stack_status: 'CREATE_COMPLETE'
        ]
      )
      cfn_client.stub_responses(
        :describe_stack_events,
        stack_events: [
          stack_id: 'stack_id',
          event_id: 'event_id',
          stack_name: 'teststack',
          timestamp: Time.new
        ]
      )
    end

    describe '#create_stack' do
      it 'raises an error' do
        allow(IO).to receive(:read).with('file').and_return('some_data')
        expect { cfn_util.create_stack('teststack', 'file') }.not_to raise_error
      end
    end
  end
end
