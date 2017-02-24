require 'spec_helper'

describe Cucloud::LambdaUtils do
  let(:lambda_client) do
    Aws::Lambda::Client.new(stub_responses: true)
  end

  let(:lambda_utils) do
    Cucloud::LambdaUtils.new lambda_client
  end

  context 'while Lambda get funtion is stubbed oout' do
    before do
      lambda_client.stub_responses(
        :get_function,
        code: {
          location: 'http://example.org',
          repository_type: 'S3'
        }
      )
    end

    describe '#download_source_for_function' do
      it 'should run without error' do
        expect { lambda_utils.download_source_for_function('Lambda-Dev') }.not_to raise_error
      end

      it 'should open the file from location assoicated with the funtion' do
        expect(lambda_utils).to receive(:open).with('http://example.org', 'rb')
        expect { lambda_utils.download_source_for_function('Lambda-Dev') }.not_to raise_error
      end

      it 'should write the file to /tmp' do
        expect(File).to receive(:open).with('/tmp/Lambda-Dev$LATEST.zip', 'wb')
        expect { lambda_utils.download_source_for_function('Lambda-Dev') }.not_to raise_error
      end

      it 'should write the file to /tmp with the correct version' do
        expect(File).to receive(:open).with('/tmp/Lambda-Dev1.zip', 'wb')
        expect { lambda_utils.download_source_for_function('Lambda-Dev', '/tmp', '1') }.not_to raise_error
      end
    end
  end

  context 'while Lambda list_versions_by_function is stubbed oout' do
    before do
      lambda_client.stub_responses(
        :list_versions_by_function,
        versions: [
          { version: '1' }, { version: '2' }, { version: '3' }
        ]
      )
    end

    describe '#get_all_versions_for_function' do
      it 'should return without an error' do
        versions = lambda_utils.get_all_versions_for_function('Lambda-Dev')
        expect(versions.length).to be 3
        expect(%w(1 2 3) - versions).to be_empty
      end
    end
  end

  context 'while Lambda list_functions is stubbed out' do
    before do
      lambda_client.stub_responses(
        :list_functions,
        functions: [
          { function_name: 'A' }, { function_name: 'B' }, { function_name: 'C' }
        ]
      )
    end

    describe '#get_all_function_names_for_account_region' do
      it 'should return without an error' do
        functions = lambda_utils.get_all_function_names_for_account_region
        expect(functions.length).to be 3
        expect(%w(A B C) - functions).to be_empty
      end
    end
  end
end
