require 'spec_helper'

describe Cucloud do
  it 'is an example of how to setup stubbing for S3 and should pass' do
    dummy = 'cu-awesome'

    Aws.config[:s3] = {
      stub_responses: {
        list_buckets: { buckets: [{ name: dummy }] }
      }
    }

    expect(Aws::S3::Client.new.list_buckets.buckets.map(&:name)).to eq [dummy]
  end

  it "should return us-east-1 as the defualt region" do
    expect(Cucloud::DEFAULT_REGION).to eq 'us-east-1'
  end

  it "should allow to change the region" do
    Cucloud.region = 'us-west-1'
    expect(Cucloud.region).to eq 'us-west-1'
    expect(Aws.config[:region]).to eq 'us-west-1'
  end
end
