class Cucloud::Ec2Utils
  MAX_TIMEOUT = 480
  SECONDS_IN_A_DAY = 86400

  UBUNTU_PATCH_COMMAND = "apt-get update; apt-get -y upgrade; reboot"
  AMAZON_PATCH_COMMAND = "yum update -y; reboot & disown "

  def initialize(ec2_client=Aws::EC2::Client.new)
    ## DI for testing purposes
    @ec2 = ec2_client
  end

  def get_instance(instance)
    ## Get instance information for a specific instance
    @ec2.describe_instances({
      instance_ids: [instance]
      })
  end

  def stop_instance(instance)
    ## Stop ec2 instance for a specific instance number. The function will wait until the instance has entered the stopped state.
    @ec2.stop_instances(instance_ids: [instance])
  end

  def start_instance(instance)
    ## Start ec2 instance for a specific instance number. The function will wait until the instance has entered the running state.
    @ec2.start_instances(instance_ids: [instance])
  end

  def rename_instance(instance, name)
    # Set the name of the instance that will be displayed in the ec2 console
  end

  def reboot_instance(instance)UBUNTU_PATCH_COMMAND = "apt-get update; apt-get -y upgrade; reboot"
AMAZON_PATCH_COMMAND = "yum update -y; reboot & disown "
  def delete_instance(instance)
    ## Terminate ec2 instance for a specific instance number.
  end

  def associate_eip(instance, allocation_id)
    ## Assoications an Elastic IP adress with a specific instance number.

    ## Return: association_id as a string in the form of eipassoc-569cd631. This is the link between between the elastic network interface and the elastic IP address.
  end

  def create_instance(options)

    ## Create ec2 instance based on parameters provided. The function will pull in default information from ?????.
    ## Options will be hash that will override the default
    ## Default will need to be pulled from ... ??

  end

  def deregister_image(image)
    # Remove private AMI
  end

  def find_ami(name)
    # Find ami based on a search of Name
  end

  def get_instances_by_tag(tag_name, tag_value)
    ## Based on tag name and value, return instances
    @ec2.describe_instances({
      filters: [
        {
          name: "tag:#{tag_name}",
          values: tag_value,
        }
      ]
    })
  end

  def stop_instances_by_tag(tag_name, tag_value)
    get_instances_by_tag(tag_name, tag_value).reservations[0].instances.each do |i|
      @ec2.stop_instances(instance_ids: [i.instance_id])
    end
  end

  def start_instances_by_tag(tag_name, tag_value)
    get_instances_by_tag(tag_name, tag_value).reservations[0].instances.each do |i|
      @ec2.start_instances(instance_ids: [i.instance_id])
    end
  end

  def send_patch_command(patch_instances, command)
    ssm = Aws::SSM::Client.new({region: 'us-east-1'})

    resp = ssm.send_command({
      instance_ids: patch_instances, # required
      document_name: "AWS-RunShellScript", # required
      timeout_seconds: 600,
      comment: "Patch It!",
      parameters: {
        "commands" => [command],
      }
    })
    puts resp.inspect
  end

  def instances_to_patch(tag_name="auto_patch", tag_value="1")
    resp = get_instances_by_tag(tag_name, tag_value)

    ubuntu_patch_instances = []
    amazon_patch_instances = []
    all_instances = []

    resp.reservations.each do |res|
      res.instances.each do |instance|
        instance.tags.each do |tag|
          if tag.key.eql?("os")
            if tag.value.eql?("ubuntu")
              ubuntu_patch_instances.push(instance.instance_id)
              all_instances.push(instance.instance_id)
            elsif tag.value.eql?("ecs") or tag.value.eql?("amazon")
              amazon_patch_instances.push(instance.instance_id)
              all_instances.push(instance.instance_id)
            end
          end
        end
      end
    end

    send_patch_command(ubuntu_patch_instances, UBUNTU_PATCH_COMMAND) if ubuntu_patch_instances.any?
    send_patch_command(amazon_patch_instances, AMAZON_PATCH_COMMAND) if amazon_patch_instances.any?

    return all_instances
  end
end
