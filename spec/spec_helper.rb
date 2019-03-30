require 'bundler/setup'
Bundler.setup
require 'pry'
require 'rack/test'
require 'rack/reducer'

RSpec.configure do |config|
  config.color = true
  config.order = :random
  config.include Rack::Test::Methods
end

module SpecRefinements
  refine Rack::MockResponse do
    define_method(:json) { JSON.parse(body) }
  end
end
