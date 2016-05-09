class Cucloud::Ec2Utils
  MAX_TIMEOUT = 480
  SECONDS_IN_A_DAY = 86400

  def initialize
    @ec2 = Aws::EC2::Client.new
  end

  def get_instances_by_tag(tag_name, tag_value)
    @ec2.describe_instances({
      filters: [
        {
          name: "tag:#{tag_name}",
          values: [tag_value],
        }
      ]
    })
  end

  def stop_instances_by_tag(tag_name, tag_value)
    get_instances_by_tag(tag_name, tag_value).each do |i|
      i.stop
    end
  end

  def start_instances_by_tag(tag_name, tag_value)
    get_instances_by_tag(tag_name, tag_value).each do |i|
      i.start
    end
  end
end
