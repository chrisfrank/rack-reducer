require 'bundler/setup'
Bundler.setup
require 'pry'
require 'rack/test'
require 'rack/reducer'
require 'sequel'
require_relative 'behavior'
ENV['RACK_ENV'] = ENV['RAILS_ENV'] = 'test'
DB = Sequel.connect "sqlite://#{__dir__}/fixtures.sqlite"

SEQUEL_QUERY = {
  dataset: DB[:artists],
  filters: [
    ->(genre:) { grep(:genre, "%#{genre}%", case_insensitive: true) },
    ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
    ->(order: 'genre') { order(order.to_sym) },
    ->(releases: ) { where(release_count: releases.to_i) },
  ]
}.freeze

RSpec.configure do |config|
  config.color = true
  config.order = :random
  config.include Rack::Test::Methods
end
