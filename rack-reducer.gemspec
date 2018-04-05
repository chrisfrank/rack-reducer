Gem::Specification.new do |spec|
  spec.name          = 'rack-reducer'
  spec.version       = '0.1.2'
  spec.authors       = ['Chris Frank']
  spec.email         = ['chris.frank@thefutureproject.org']
  spec.summary       = 'Dynamically filter data via URL params, in any Rack app.'
  spec.description   = 'Dynamically filter, sort, and paginate data via URL params, in any Rack app.'
  spec.homepage      = 'https://github.com/chrisfrank/rack-reducer'
  spec.license       = 'MIT'
  spec.files         = Dir['README.md', 'lib/**/*']
  spec.test_files    = Dir['spec/**/*.rb']
  spec.require_path  = 'lib'

  spec.add_development_dependency 'bundler', '~> 1'
  spec.add_development_dependency 'benchmark-ips', '~> 2'
  spec.add_development_dependency 'pry', '~> 0'
  spec.add_development_dependency 'hanami', '~> 1'
  spec.add_development_dependency 'hanami-model', '~> 1'
  spec.add_development_dependency 'rack-test', '~> 0'
  spec.add_development_dependency 'rails', '~> 5'
  spec.add_development_dependency 'rake', '~> 12'
  spec.add_development_dependency 'roda', '~> 3'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'sequel', '~> 4'
  spec.add_development_dependency 'sinatra', '~> 2'
  spec.add_development_dependency 'sqlite3', '~> 1'

  spec.add_dependency 'rack', '>= 1.6', '< 3'
  spec.required_ruby_version = '>= 2.2'
end
