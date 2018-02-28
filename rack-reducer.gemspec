Gem::Specification.new do |spec|
  spec.name          = 'rack-reducer'
  spec.version       = '0.1.0'
  spec.authors       = ['Chris Frank']
  spec.email         = ['chris.frank@thefutureproject.org']
  spec.description   = 'Safe, simple data filtering via params, in any Rack app'
  spec.summary       = 'Safe, simple data filtering via params, in any Rack app'
  spec.homepage      = 'https://github.com/chrisfrank/rack-reducer'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($RS)
  spec.test_files    = spec.files.grep('^(spec)/')
  spec.require_path = 'lib'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'sequel'
  spec.add_development_dependency 'sinatra'
  spec.add_development_dependency 'sqlite3'

  spec.add_dependency 'rack'
end
