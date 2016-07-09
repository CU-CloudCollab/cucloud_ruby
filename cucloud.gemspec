# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cucloud/version'

Gem::Specification.new do |spec|
  spec.name          = 'cucloud'
  spec.version       = Cucloud::VERSION
  spec.authors       = ['sbower']
  spec.email         = ['shawn.bower@gmail.com']

  spec.summary       = 'The cucloud module is intended to provide functionality requiring more customization than ' \
                       'could otherwise be simply accomplished with a cloud specific command line interface, e.g. ' \
                       'AWS CLI'
  spec.description   = 'The cucloud module is intended to provide functionality requiring more customization than ' \
                       'could otherwise be simply accomplished with a cloud specific command line interface, e.g. ' \
                       'AWS CLI'
  spec.homepage      = 'https://github.com/CU-CloudCollab/cucloud_ruby'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk', '~> 2'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
end
