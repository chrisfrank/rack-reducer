require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :cop do
  sh 'bundle exec rubocop lib'
end

task :doc do
  sh 'bundle exec yard doc'
end

task :commit do
  sh 'bundle exec rake'
  sh 'git add -A && git commit --verbose'
end

task :bench do
  sh 'bundle exec rspec spec/benchmarks.rb'
end

task default: %i[cop spec doc]
