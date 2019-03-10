lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/reducer/version'

Gem::Specification.new do |spec|
  spec.name          = 'rack-reducer'
  spec.version       = Rack::Reducer::VERSION
  spec.authors       = ['Chris Frank']
  spec.email         = ['chris.frank@future.com']
  spec.summary       = 'Dynamically filter data via URL params, in any Rack app.'
  spec.description   = 'Dynamically filter data via URL params, in any Rack app.'
  spec.homepage      = 'https://github.com/chrisfrank/rack-reducer'
  spec.license       = 'MIT'
  spec.files         = Dir['README.md', 'lib/**/*']
  spec.test_files    = Dir['spec/**/*.rb']
  spec.require_path  = 'lib'

  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'benchmark-ips'
  spec.add_development_dependency 'benchmark-memory'
  spec.add_development_dependency 'pry', '~> 0.11'
  spec.add_development_dependency 'rack-test', '~> 0'
  spec.add_development_dependency 'rake', '~> 12'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'rubocop', '~> 0.61'
  spec.add_development_dependency 'yard', '~> 0.9'

  spec.add_dependency 'rack', '>= 1.6', '< 3'
  spec.required_ruby_version = '>= 2.3'
end
