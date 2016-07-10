# Cucloud

The cucloud module is intended to serve as a lightweight wrapper around the AWS SDK that can be used to share common functionality across various AWS utilities and tools that we develop at Cornell.  Goals:

* Standardize credential management and client instantiation so that all of our utilities use the same approach
* Encapsulate the work of building json/hash requests and parsing responses, to provide a simple/consistent API through which our utilities interact with AWS
* Provide methods that fill in "gaps" in the SDK functionality (e.g., make it easier to work across SDK silos; reduce multi-step chained api calls to single method calls)
* Provide a standard approach to unit testing using rspec and AWS stubs

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cucloud'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cucloud

## Usage

Within an app - simply require the cucloud gem as noted above, then include functionality as needed.

For example, to use the Auto Scaling Group functionality:

```
# get the autoscale group utilities
asg_utils = Cucloud::AsgUtils.new

# get an autoscale group by name
asg = asg_utils.get_asg_by_name('my-autoscale-group')

# output the launch configuration name
puts asg.launch_configuration_name

```

Note - the cucloud library assumes that environment credentials are available to the AWS SDK.  See https://blogs.aws.amazon.com/security/post/Tx3D6U6WSFGOK2H/A-New-and-Standardized-Way-to-Manage-Credentials-in-the-AWS-SDKs for more info.

## Example Utility Implementations

Utilities that use this API:

* Autoscale AMI Updater: https://github.com/CU-CloudCollab/asg-ami-update


## Development

After checking out the repo, run `bin/setup` to install dependencies.

To run styleguide/syntax tests:
``` $ bundle exec rubocop ```

To run unit tests:
``` $ bundle exec rake spec ```

To generate documentation:
``` bundle exec yard ```

To install this gem onto your local machine:
``` bundle exec rake install ```

It's helpful to reference a local copy of the gem while developing (so you can add methods to cucloud and reference them in the utility you are developing) -- see https://rossta.net/blog/how-to-specify-local-ruby-gems-in-your-gemfile.html for a recommended approach.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/CU-CloudCollab/cucloud_ruby. The library includes functions that have been needed somewhere already - it is in no way complete yet and we love contributions!

General guidance for contributions:

* cucloud is intended to be an API consumed by other applications - in general, any user input/output/interaction should be pushed to utilities that consume this library.
* Pull requests should include code and passing rspec unit tests for any new methods.
* Methods and classes should be documented in the YARD format (http://yardoc.org/).
* Code should conform to Ruby Community Styleguide and pass rubocop checks using the included rubocop config (https://github.com/bbatsov/ruby-style-guide).

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

