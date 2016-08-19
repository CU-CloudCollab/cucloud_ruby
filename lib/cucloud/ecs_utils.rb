module Cucloud
  # ECSUtils class - anything ecs related goes here!
  class EcsUtils
    # Define error classes
    class InvalidTaskDefinitionError < ArgumentError
    end

    # Constructor for EcsUtils class
    # @param ecs_client [Aws::ECS::Client] AWS ECS SDK Client
    def initialize(ecs_client = Aws::ECS::Client.new)
      ## DI for testing purposes
      @ecs = ecs_client
    end

    # Get task definition details for given revision of task.  If revision is nil, return latest task
    # @param family_prefix [String] Task family prefix
    # @param revision [Integer] Specific revision
    # @return [Aws::ECS::Types::TaskDefinition] Task definition object
    def get_task_definition(family_prefix, revision = nil)
      task = if revision.nil?
               family_prefix
             else
               "#{family_prefix}:#{revision}"
             end

      @ecs.describe_task_definition(task_definition: task)['task_definition']
    end

    # Generate task definition based on provided example - replace w/ new image
    # @param task_definition [Aws::ECS::Types::TaskDefinition] Task definition object
    # @param container_name [String] Name of container for which image should be updated
    # @param new_image_dtr_uri [String] Location of new image in registry
    def generate_td_options_hash_with_new_image(task_definition, container_name, new_image_dtr_uri)
      # make sure we got a valid launch config
      raise InvalidTaskDefinitionError.new,
            'Provided task definition is not valid' unless task_definition.is_a? Aws::ECS::Types::TaskDefinition

      # convert to hash (required for aws sdk) and update necessary values
      options_hash = task_definition.to_h

      # Definitions can contain more than one container. Update the targetted def.
      target_container_index = options_hash[:container_definitions].index { |c| c[:name] == container_name }
      options_hash[:container_definitions][target_container_index][:image] = new_image_dtr_uri

      # request cannot have arn, revision or keys with empty values
      options_hash.delete_if do |key, value|
        key == :task_definition_arn || key == :revision || key == :status || key == :requires_attributes || value == ''
      end
    end

    # Create new task definition in AWS
    # @param options [Hash] Options hash to be passed along in request
    # @return [String] ARN of new task definition
    def register_task_definition(task_definition)
      @ecs.register_task_definition(task_definition)['task_definition']['task_definition_arn']
    end
  end
end
