require 'bundler/setup'
Bundler.setup
require 'pry'
require 'rack/test'
require 'rack/reducer'
require_relative 'fixtures/db'

# Mock an ActiveRecord/Sequel class to 'query' a DB fixture
class Artist
  def self.all
    new DB[:artists]
  end

  def self.search(args)
    all.search(args)
  end

  def initialize(data)
    @data = data
  end

  def search(args)
    self.class.new(
      args.reduce(@data) do |data, (key, value)|
        data.select { |item| item[key].downcase.match value.downcase }
      end
    )
  end

  def all
    @data
  end
end

FILTERS = [
  ->(genre:, name: 'jim') { search(genre: genre) },
  ->(name:) { search(name: name) },
]

RSpec.configure do |config|
  config.color = true
  config.order = :random
  config.include Rack::Test::Methods
end
