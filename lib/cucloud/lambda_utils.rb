module Cucloud
  # LambdaUtils - Utilities for woking with Lambda functions
  class LambdaUtils
    require 'open-uri'

    # Constructor for LambdaUtils class
    # @param lambda_client [Aws::Lambda::Client] AWS Lambda SDK Client
    def initialize(lambda_client = Aws::Lambda::Client.new)
      @lambda = lambda_client
    end

    # Download the source pacakge for a given lambda function
    # @param function_name [String] Name of the lambda function
    # @param path [String] Local path to write the source pacakge to, defaults to /tmp
    # @param version [String] Version of the function to download, defaults to $LATEST
    # @return [String] Local path to the file
    def download_source_for_function(function_name, path = '/tmp', version = '$LATEST')
      lambda_function = @lambda.get_function(function_name: function_name,
                                             qualifier: version)

      file_path = path + '/' + function_name + version + '.zip'
      File.open(file_path, 'wb') do |saved_file|
        open(lambda_function[:code][:location], 'rb') do |read_file|
          saved_file.write(read_file.read)
        end
      end
      file_path
    end

    # Return all versions of a lambda function
    # @param function_name [String] Name of the lambda function
    # @return [Array] Array of strings representing the versions of the lambda function
    def get_all_versions_for_function(function_name)
      version_response = @lambda.list_versions_by_function(function_name: function_name)
      version_response.versions.map { |x| x[:version] }
    end

    # Return all funtion names for an account
    # @return [Array] Array of strings representing the function names
    def get_all_function_names_for_account_region
      funtions_response = @lambda.list_functions
      funtions_response.functions.map { |x| x[:function_name] }
    end
  end
end
