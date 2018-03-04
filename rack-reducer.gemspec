Gem::Specification.new do |spec|
  spec.name          = 'rack-reducer'
  spec.version       = '0.1.0'
  spec.authors       = ['Chris Frank']
  spec.email         = ['chris.frank@thefutureproject.org']
  spec.summary       = 'Safely map URL params to database filters, in any Rack app.'
  spec.description   = 'Safely map URL params to database filters, in any Rack app. If your users need to filter data by making HTTP requests, this gem can help.'
  spec.homepage      = 'https://github.com/chrisfrank/rack-reducer'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($RS)
  spec.test_files    = spec.files.grep('^(spec)/')
  spec.require_path = 'lib'

  spec.add_development_dependency 'bundler', '~> 1'
  spec.add_development_dependency 'benchmark-ips', '~> 2'
  spec.add_development_dependency 'pry', '~> 0'
  spec.add_development_dependency 'rack-test', '~> 0'
  spec.add_development_dependency 'rails', '~> 5'
  spec.add_development_dependency 'rake', '~> 12'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'sequel', '~> 5'
  spec.add_development_dependency 'sinatra', '~> 2'
  spec.add_development_dependency 'sqlite3', '~> 1'

  spec.add_dependency 'rack', '>= 1.6', '< 3'
  spec.required_ruby_version = '>= 2.1'
end
