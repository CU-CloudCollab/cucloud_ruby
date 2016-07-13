# coding: utf-8
# rubocop:disable Style/WordArray
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cucloud/version'

Gem::Specification.new do |spec|
  spec.name          = 'cucloud'
  spec.version       = Cucloud::VERSION
  spec.authors       = ['sbower', 'bharanin', 'sross07']

  spec.email         = ['shawn.bower@gmail.com', 'bmh67@cornell.edu', 'sr523@cornell.edu']

  spec.summary       = 'The cucloud module is intended to serve as a lightweight wrapper around the AWS SDK that ' \
                       'can be used to share common functionality across various AWS utilities and tools that we ' \
                       'develop at Cornell'
  spec.description   = 'The cucloud module is intended to serve as a lightweight wrapper around the AWS SDK that ' \
                       'can be used to share common functionality across various AWS utilities and tools that we ' \
                       'develop at Cornell'
  spec.homepage      = 'https://github.com/CU-CloudCollab/cucloud_ruby'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk', '~> 2'
  spec.add_dependency 'uuid', '~> 2.3'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.40.0'
  spec.add_development_dependency 'yard', '~> 0.9.0'
end
