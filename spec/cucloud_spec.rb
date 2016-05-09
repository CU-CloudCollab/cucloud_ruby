require 'spec_helper'

describe Cucloud do
  it "example of how to setup stubbing for S3 should pass" do

    dummy_value = 'cu-awesome'

    Aws.config[:s3] = {
      stub_responses: {
        list_buckets: { buckets:[{name:dummy_value}]}
      }
    }

    expect(Aws::S3::Client.new.list_buckets.buckets.map(&:name)).to eq [dummy_value]
  end
end
