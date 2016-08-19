require 'spec_helper'

describe Cucloud::EcsUtils do
  let(:ecs_client) do
    Aws::ECS::Client.new(stub_responses: true)
  end

  let(:ecs_util) do
    Cucloud::EcsUtils.new ecs_client
  end

  it '.new default optional should be successful' do
    expect(Cucloud::EcsUtils.new).to be_a_kind_of(Cucloud::EcsUtils)
  end

  it 'dependency injection ecs_client should be successful' do
    expect(Cucloud::EcsUtils.new(ecs_client)).to be_a_kind_of(Cucloud::EcsUtils)
  end

  context 'while describe_task_definition and register_task_definition are stubbed out with test responses' do
    before do
      ecs_client.stub_responses(
        :describe_task_definition,
        task_definition: {
          container_definitions: [
            {
              name: 'test_container',
              image: 'dtr.cucloud.net/test/test-image:953cb0f5e478',
              cpu: 10,
              memory: 30,
              memory_reservation: 30,
              links: %w(
                link1
                link2
              ),
              port_mappings: [
                {
                  container_port: 80,
                  host_port: 4444,
                  protocol: 'tcp'
                }
              ],
              essential: true,
              entry_point: %w(
                entry_point_1
                entry_point_2
              ),
              command: [
                'command 1',
                'command 2'
              ],
              environment: [
                {
                  name: 'env_var_1',
                  value: 'test1'
                },
                {
                  name: 'env_var_2',
                  value: 'test2'
                }
              ],
              mount_points: [
                {
                  source_volume: 'volume 1',
                  container_path: '/path',
                  read_only: false
                }
              ],
              volumes_from: [
                source_container: 'source 1',
                read_only: false
              ],
              hostname: 'hostname test',
              user: 'user',
              working_directory: '/working_dir',
              disable_networking: false,
              privileged: false,
              readonly_root_filesystem: true,
              dns_servers: [
                'dns1.server.com',
                'dns2.server.com'
              ],
              dns_search_domains: [
                'search1.domain.com',
                'search2.domain.com'
              ],
              extra_hosts: [
                {
                  hostname: 'hostname1',
                  ip_address: '192.168.0.1'
                },
                {
                  hostname: 'hostname2',
                  ip_address: '192.168.0.2'
                }
              ],
              docker_security_options: [
                'option 1',
                'option 2'
              ],
              docker_labels: {
                'test1' => 'test',
                'test2' => 'test2'
              },
              ulimits: [
                {
                  name: 'cpu',
                  soft_limit: 30,
                  hard_limit: 30
                },
                {
                  name: 'memory',
                  soft_limit: 50,
                  hard_limit: 50
                }
              ],
              log_configuration: {
                log_driver: 'syslog',
                options: {
                  'syslog-tag' => 'pidash_auth_test'
                }
              }
            }
          ],
          task_definition_arn: 'old-task-def-arn',
          family: 'task_def_family',
          task_role_arn: 'test-role-arn',
          network_mode: 'bridge',
          revision: 20,
          volumes: [
            {
              name: 'vol1',
              host: {
                source_path: 'test path'
              }
            }
          ],
          status: 'ACTIVE',
          requires_attributes: [
            {
              name: 'test attr 1',
              value: 'value attr 1'
            },
            {
              name: 'test attr 2',
              value: 'value attr 2'
            }
          ]
        }
      )

      ecs_client.stub_responses(
        :register_task_definition,
        task_definition: {
          container_definitions: [
            {
              name: 'test_container',
              image: 'dtr.cucloud.net/test/test-image:953cb0f5e498',
              cpu: 10,
              memory: 30,
              memory_reservation: 30,
              links: %w(
                link1
                link2
              ),
              port_mappings: [
                {
                  container_port: 80,
                  host_port: 4444,
                  protocol: 'tcp'
                }
              ],
              essential: true,
              entry_point: %w(
                entry_point_1
                entry_point_2
              ),
              command: [
                'command 1',
                'command 2'
              ],
              environment: [
                {
                  name: 'env_var_1',
                  value: 'test1'
                },
                {
                  name: 'env_var_2',
                  value: 'test2'
                }
              ],
              mount_points: [
                {
                  source_volume: 'volume 1',
                  container_path: '/path',
                  read_only: false
                }
              ],
              volumes_from: [
                source_container: 'source 1',
                read_only: false
              ],
              hostname: 'hostname test',
              user: 'user',
              working_directory: '/working_dir',
              disable_networking: false,
              privileged: false,
              readonly_root_filesystem: true,
              dns_servers: [
                'dns1.server.com',
                'dns2.server.com'
              ],
              dns_search_domains: [
                'search1.domain.com',
                'search2.domain.com'
              ],
              extra_hosts: [
                {
                  hostname: 'hostname1',
                  ip_address: '192.168.0.1'
                },
                {
                  hostname: 'hostname2',
                  ip_address: '192.168.0.2'
                }
              ],
              docker_security_options: [
                'option 1',
                'option 2'
              ],
              docker_labels: {
                'test1' => 'test',
                'test2' => 'test2'
              },
              ulimits: [
                {
                  name: 'cpu',
                  soft_limit: 30,
                  hard_limit: 30
                },
                {
                  name: 'memory',
                  soft_limit: 50,
                  hard_limit: 50
                }
              ],
              log_configuration: {
                log_driver: 'syslog',
                options: {
                  'syslog-tag' => 'pidash_auth_test'
                }
              }
            }
          ],
          task_definition_arn: 'new-task-def-arn',
          family: 'task_def_family',
          task_role_arn: 'test-role-arn',
          network_mode: 'bridge',
          revision: 20,
          volumes: [
            {
              name: 'vol1',
              host: {
                source_path: 'test path'
              }
            }
          ],
          status: 'ACTIVE',
          requires_attributes: [
            {
              name: 'test attr 1',
              value: 'value attr 1'
            },
            {
              name: 'test attr 2',
              value: 'value attr 2'
            }
          ]
        }
      )
    end

    describe '#get_task_definition' do
      it 'should return without an error when passed task family and revision' do
        expect { ecs_util.get_task_definition('test', 234) }.not_to raise_error
      end

      it 'should return expected result when passed task family and revision' do
        expect(ecs_util.get_task_definition('test', 234).family).to eq 'task_def_family'
        expect(ecs_util.get_task_definition('test', 234).task_role_arn).to eq 'test-role-arn'
        expect(
          ecs_util.get_task_definition('test', 234).container_definitions.first.image
        ).to eq 'dtr.cucloud.net/test/test-image:953cb0f5e478'
        expect(ecs_util.get_task_definition('test', 234).container_definitions.first.cpu).to eq 10
      end

      it 'should return without an error when passed task family' do
        expect { ecs_util.get_task_definition('test') }.not_to raise_error
      end

      it 'should return expected result when passed task family' do
        expect(ecs_util.get_task_definition('test').family).to eq 'task_def_family'
        expect(ecs_util.get_task_definition('test').task_role_arn).to eq 'test-role-arn'
        expect(
          ecs_util.get_task_definition('test').container_definitions.first.image
        ).to eq 'dtr.cucloud.net/test/test-image:953cb0f5e478'
        expect(ecs_util.get_task_definition('test').container_definitions.first.cpu).to eq 10
      end
    end

    describe '#generate_td_options_hash_with_new_image' do
      let(:task) { ecs_util.get_task_definition('test') }
      let(:target_container) { 'test_container' }
      let(:image_id) { 'dtr.cucloud.net/test/test-image:953cb0f5e498' }

      it 'should throw InvalidTaskDefinitionError when passed an invalid task def' do
        expect do
          ecs_util.generate_td_options_hash_with_new_image('invalid task def', 'test_container', 'test image')
        end.to raise_error(Cucloud::EcsUtils::InvalidTaskDefinitionError)
      end

      it 'should return without an error when passed valid task and image id' do
        expect { ecs_util.generate_td_options_hash_with_new_image(task, target_container, image_id) }.not_to raise_error
      end

      it 'should return hash with new image' do
        expect(
          ecs_util.generate_td_options_hash_with_new_image(task, target_container, image_id)[:container_definitions]
            .first[:image]
        ).to eq image_id
      end

      it 'should not include a launch config arn' do
        expect(
          ecs_util.generate_td_options_hash_with_new_image(task, target_container, image_id)[:task_definition_arn].nil?
        ).to eq true
      end

      it 'should not include a revision' do
        expect(
          ecs_util.generate_td_options_hash_with_new_image(task, target_container, image_id)[:revision].nil?
        ).to eq true
      end

      it 'should not include a status' do
        expect(
          ecs_util.generate_td_options_hash_with_new_image(task, target_container, image_id)[:status].nil?
        ).to eq true
      end

      it 'should not include requires_attributes' do
        expect(
          ecs_util.generate_td_options_hash_with_new_image(task, target_container, image_id)[:requires_attributes].nil?
        ).to eq true
      end

      it 'should not include any empty string values' do
        expect(
          ecs_util.generate_td_options_hash_with_new_image(task, target_container, image_id)
            .select { |_k, v| v == '' }.empty?
        ).to eq true
      end
    end

    describe '#register_task_definition' do
      let(:task) { ecs_util.get_task_definition('test') }
      let(:target_container) { 'test_container' }
      let(:image_id) { 'dtr.cucloud.net/test/test-image:953cb0f5e478' }

      it 'should return without an error' do
        expect do
          ecs_util.register_task_definition(ecs_util.generate_td_options_hash_with_new_image(task,
                                                                                             target_container,
                                                                                             image_id))
        end.not_to raise_error
      end

      it 'should return ARN of new task' do
        expect(
          ecs_util.register_task_definition(ecs_util.generate_td_options_hash_with_new_image(task,
                                                                                             target_container,
                                                                                             image_id))
        ).to eq 'new-task-def-arn'
      end
    end
  end

  context 'while describe_services is mocked with response' do
    before do
      ecs_client.stub_responses(
        :describe_services,
        services: [
          {
            service_arn: 'test-service-arn',
            service_name: 'test-service-name',
            cluster_arn: 'cluster-arn',
            load_balancers: [
              target_group_arn: 'target-group-arn',
              load_balancer_name: 'elb-name',
              container_name: 'container-name',
              container_port: 80
            ],
            status: 'ACTIVE',
            desired_count: 1,
            running_count: 2,
            pending_count: 0,
            task_definition: 'task-def-arn',
            deployment_configuration: {
              maximum_percent: 150,
              minimum_healthy_percent: 50
            },
            deployments: [
              id: 'deployment-id',
              status: 'deployment-status',
              task_definition: 'deployment-task-arn',
              desired_count: 1,
              pending_count: 1,
              running_count: 0,
              created_at: Time.new(2016, 7, 9, 13, 30, 0),
              updated_at: Time.new(2016, 7, 9, 13, 30, 0)
            ],
            role_arn: 'service-role-arn',
            events: [
              id: 'event-id',
              created_at: Time.new(2016, 7, 9, 13, 30, 0),
              message: 'test-event-message'
            ],
            created_at: Time.new(2016, 7, 9, 13, 30, 0)
          }
        ],
        failures: [
          arn: 'failure-arn',
          reason: 'failure-reason'
        ]
      )
    end

    describe '#get_service' do
      it 'should return without an error' do
        expect { ecs_util.get_service('cluster_name', 'service_name') }.not_to raise_error
      end

      it 'should return expected value' do
        expect(ecs_util.get_service('cluster_name', 'service_name')[:service_arn]).to eq 'test-service-arn'
        expect(ecs_util.get_service('cluster_name', 'service_name')[:service_name]).to eq 'test-service-name'
      end
    end
  end
end
