require 'spec_helper'

describe Cucloud::Ec2Utils do
  let(:ec2_client) {
    Aws::EC2::Client.new(stub_responses: true)
  }

  let(:ec_util){
    Cucloud::Ec2Utils.new ec2_client
  }

  context "when describe_instances is stubbed to return a single instance" do
    before do
      ec2_client.stub_responses(
        :describe_instances, {
          :next_token => nil,
          :reservations => [{:instances=>[{:instance_id => "i-1", :state => {:name => "running"}, :tags =>[{:key => "Name", :value => "example-1" }]}]}]
        }
      )
    end

    it ".new default optional should be successful" do
      expect(Cucloud::Ec2Utils.new).to be_a_kind_of(Cucloud::Ec2Utils)
    end

    it "dependency injectin ec2_client should be successful" do
      expect(Cucloud::Ec2Utils.new ec2_client).to be_a_kind_of(Cucloud::Ec2Utils)
    end

    it "'get_instances_by_tag' should return '> 1' where tage_name= Name, and tag_value= example-1" do
      expect(ec_util.get_instances_by_tag('Name', 'example-1').to_a.size).to eq 1
    end

    it "'stop_instances_by_tag' should return without an error" do

      #ec_util.stop_instances_by_tag('Name', 'example-1')
    end

    it "'start_instances_by_tag' should return without an error" do
      #ec_util.start_instances_by_tag('Name', 'example-1')
    end
  end
end
