require 'spec_helper'

## Written by Scott Ross
## Unit testing ec2_utils
## Spring 2016

describe Cucloud::Ec2Utils do
  let(:ec2_client) {
    Aws::EC2::Client.new(stub_responses: true)
  }

  let(:ec_util){
    Cucloud::Ec2Utils.new ec2_client
  }

  context "while ec2 is stubbed out" do
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
      expect(ec_util.get_instances_by_tag('Name', ['example-1']).to_a.size).to eq 1
    end

    it "'stop_instances_by_tag' should return without an error" do
      expect{ec_util.stop_instances_by_tag('Name', ['example-1'])}.not_to raise_error
    end

    it "'start_instances_by_tag' should return without an error" do
      expect{ec_util.start_instances_by_tag('Name', ['example-1'])}.not_to raise_error
    end

    it "should 'get_instance' and the instance id should eq i-1" do
      expect(ec_util.get_instance('i-1').reservations[0].instances[0].instance_id.to_s).to eq 'i-1'
    end

    it "should 'start_instance' without an error" do
      expect{ec_util.start_instance('i-1')}.not_to raise_error
    end

    it "should 'stop_instance' without an error" do
      expect{ec_util.stop_instance('i-1')}.not_to raise_error
    end

    it "should 'reboot_instance' without an error" do
      expect{ec_util.reboot_instance('i-1')}.not_to raise_error
    end

  end
end
