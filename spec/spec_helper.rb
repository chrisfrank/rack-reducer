ENV['RACK_ENV'] = ENV['RAILS_ENV'] = 'test'
require 'bundler/setup'
Bundler.setup
require 'pry'
require 'rack/test'
require 'rack/reducer'
require_relative 'fixtures'
require_relative 'support'

RSpec.configure do |config|
  config.color = true
  config.order = :random
  config.include Rack::Test::Methods
end
