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

      # https://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#describe_task_definition-instance_method
      @ecs.describe_task_definition(task_definition: task)['task_definition']
    end

    # Generate task definition options hash (that can be sumitted to AWS SDK) w/ new image
    # @param task_definition [Aws::ECS::Types::TaskDefinition] Task definition object
    # @param container_name [String] Name of container for which image should be updated
    # @param new_image_dtr_uri [String] Location of new image in registry
    # @return [Hash] An options hash that can be submitted via AWS sdk
    def generate_td_options_hash_with_new_image(task_definition, container_name, new_image_dtr_uri)
      options_hash = generate_td_options_hash(task_definition)

      # Definitions can contain more than one container. Update the targetted def.
      target_container_index = options_hash[:container_definitions].index { |c| c[:name] == container_name }
      options_hash[:container_definitions][target_container_index][:image] = new_image_dtr_uri

      options_hash
    end

    # Generate task definition options hash (that can be sumitted to AWS SDK) from existing definition
    # @param task_definition [Aws::ECS::Types::TaskDefinition] Task definition object
    # @return [Hash] An options hash that can be submitted via AWS sdk
    def generate_td_options_hash(task_definition)
      # make sure we got a valid launch config
      raise InvalidTaskDefinitionError.new,
            'Provided task definition is not valid' unless task_definition.is_a? Aws::ECS::Types::TaskDefinition

      # convert to hash (required for aws sdk) and update necessary values
      options_hash = task_definition.to_h

      # request cannot have arn, revision or keys with empty values
      options_hash.delete_if do |key, value|
        key == :task_definition_arn || key == :revision || key == :status || key == :requires_attributes || value == ''
      end
    end

    # Create new task definition in AWS
    # @param options [Hash] Options hash to be passed along in request
    # @return [Hash] Hash w/ task definition arn, family and revision
    def register_task_definition(task_definition)
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#register_task_definition-instance_method
      new_def = @ecs.register_task_definition(task_definition)['task_definition']

      {
        arn: new_def['task_definition_arn'],
        family: new_def['family'],
        revision: new_def['revision']
      }
    end

    # Get definition for service based on service name
    # @param cluster_name [String] Name of cluster on which this service is configured
    # @param service_name [String] Name of service
    # @return [Aws::ECS::Types::Service] Service definition
    def get_service(cluster_name, service_name)
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#describe_services-instance_method
      @ecs.describe_services(cluster: cluster_name, services: [service_name])[:services].first
    end

    # Update the task definition associated with a service - this effectively deploys new task on service
    # @param cluster_name [String] Name of cluster on which this service is configured
    # @param service_name [String] Name of service
    # @param task_arn [String] Task ARN to be used by service
    # @return [Aws::ECS::Types::Service] Updated service
    def update_service_task_definition!(cluster_name, service_name, task_arn)
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#update_service-instance_method
      @ecs.update_service(cluster: cluster_name,
                          service: service_name,
                          task_definition: task_arn)['service']
    end
  end
end
