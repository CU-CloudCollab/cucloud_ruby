module Cucloud
  # CFNUtils - Utilities for CloudFormation
  class CfnUtils
    # Define some error classes
    class UnknownServiceError < StandardError
    end

    def initialize(cfn = Aws::CloudFormation::Client.new)
      @cfn = cfn
    end

    # Create cloud formation stack from template
    # @param stack_name [string] name of the the cfn stack
    # @param template_json [string] file path to cfn template json
    # @return [String] representing the stack events from the run
    def create_stack(stack_name, template_json)
      manage_stack(stack_name, template_json)
    end

    # Update cloud formation stack from template
    # @param stack_name [string] name of the the cfn stack
    # @param template_json [string] file path to cfn template json
    # @return [String] representing the stack events from the run
    def update_stack(stack_name, template_json)
      manage_stack(stack_name, template_json, :update_stack)
    end

    private

    # Manage cloud formation stack from template,
    # abstracts logic for both the create and update
    # @param stack_name [string] name of the the cfn stack
    # @param template_json [string] file path to cfn template json
    # @return [String] representing the stack events from the run
    def manage_stack(stack_name, template_json, action = :create_stack)
      template = IO.read(template_json)

      response = @cfn.send(action, stack_name: stack_name,
                                   template_body: template,
                                   capabilities: %w[CAPABILITY_IAM CAPABILITY_NAMED_IAM])

      raise UnknownServiceError unless response.successful?

      wait_event = action == :create_stack ? :stack_create_complete : :stack_update_complete

      @cfn.wait_until(wait_event, stack_name: stack_name)
      @cfn.describe_stack_events(stack_name: stack_name)
    end
  end
end
