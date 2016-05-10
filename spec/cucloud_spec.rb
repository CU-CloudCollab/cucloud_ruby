require 'spec_helper'

describe Cucloud do
  it "is an example of how to setup stubbing for S3 and should pass" do

    dummy = 'cu-awesome'

    Aws.config[:s3] = {
      stub_responses: {
        list_buckets: { buckets:[{name:dummy}]}
      }
    }

    expect(Aws::S3::Client.new.list_buckets.buckets.map(&:name)).to eq [dummy]
  end
end
