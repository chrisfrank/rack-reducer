require 'bundler/setup'
Bundler.setup
require 'pry'
require 'rack/test'
require 'rack/reducer'
Dir["#{__dir__}/fixtures/*.rb"].each { |file| require file }
require_relative 'support'

RSpec.configure do |config|
  config.color = true
  config.order = :random
  config.include Rack::Test::Methods
end
