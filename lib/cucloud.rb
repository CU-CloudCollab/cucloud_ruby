require 'aws-sdk'

# Main Cucloud Module namespace and defaults
module Cucloud
  require 'cucloud/version'
  require 'cucloud/ec2_utils'
  require 'cucloud/asg_utils'
  require 'cucloud/ssm_utils'
  require 'cucloud/iam_utils'

  DEFAULT_REGION = 'us-east-1'.freeze

  Aws.config = { region: DEFAULT_REGION }

  CORNELL_SAML_X509 = %(<ds:X509Certificate>MIIDSDCCAjCgAwIBAgIVAOZ8NfBem6sHcI7F39sYmD/JG4YDMA0GCSqGSIb3DQEB
BQUAMCIxIDAeBgNVBAMTF3NoaWJpZHAuY2l0LmNvcm5lbGwuZWR1MB4XDTA5MTEy
MzE4NTI0NFoXDTI5MTEyMzE4NTI0NFowIjEgMB4GA1UEAxMXc2hpYmlkcC5jaXQu
Y29ybmVsbC5lZHUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCTURo9
90uuODo/5ju3GZThcT67K3RXW69jwlBwfn3png75Dhyw9Xa50RFv0EbdfrojH1P1
9LyfCjubfsm9Z7FYkVWSVdPSvQ0BXx7zQxdTpE9137qj740tMJr7Wi+iWdkyBQS/
bCNhuLHeNQor6NXZoBgX8HvLy4sCUb/4v7vbp90HkmP3FzJRDevzgr6PVNqWwNqp
tZ0vQHSF5D3iBNbxq3csfRGQQyVi729XuWMSqEjPhhkf1UjVcJ3/cG8tWbRKw+W+
OIm71k+99kOgg7IvygndzzaGDVhDFMyiGZ4njMzEJT67sEq0pMuuwLMlLE/86mSv
uGwO2Qacb1ckzjodAgMBAAGjdTBzMFIGA1UdEQRLMEmCF3NoaWJpZHAuY2l0LmNv
cm5lbGwuZWR1hi5odHRwczovL3NoaWJpZHAuY2l0LmNvcm5lbGwuZWR1L2lkcC9z
aGliYm9sZXRoMB0GA1UdDgQWBBSQgitoP2/rJMDepS1sFgM35xw19zANBgkqhkiG
9w0BAQUFAAOCAQEAaFrLOGqMsbX1YlseO+SM3JKfgfjBBL5TP86qqiCuq9a1J6B7
Yv+XYLmZBy04EfV0L7HjYX5aGIWLDtz9YAis4g3xTPWe1/bjdltUq5seRuksJjyb
prGI2oAv/ShPBOyrkadectHzvu5K6CL7AxNTWCSXswtfdsuxcKo65tO5TRO1hWlr
7Pq2F+Oj2hOvcwC0vOOjlYNe9yRE9DjJAzv4rrZUg71R3IEKNjfOF80LYPAFD2Sp
p36uB6TmSYl1nBmS5LgWF4EpEuODPSmy4sIV6jl1otuyI/An2dOcNqcgu7tYEXLX
C8N6DXggDWPtPRdpk96UW45huvXudpZenrcd7A==</ds:X509Certificate>).freeze

  def region
    @region
  end

  def region=(region)
    @region = region
    Aws.config = { region: @region }
  end

  module_function :region, :region=
end
