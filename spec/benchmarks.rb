require 'rspec'
require_relative 'spec_helper'
require 'json'
require 'benchmark/ips'
require 'benchmark/memory'
require_relative 'fixtures'

TestReducer = Rack::Reducer.create(
  Fixtures::DB[:artists],
  ->(genre:) {
    select { |item| item[:genre].match(/#{genre}/i) }
  },
  ->(name:) {
    select { |item| item[:name].match(/#{name}/i) }
  },
)

Benchmark.ips do |bm|
  params = { name: 'blake', genre: 'electronic' }

  bm.report('conditionals') do
    @artists = Fixtures::DB[:artists]
    if (genre = params[:genre])
      @artists = @artists.select { |item| item[:genre].match(/#{genre}/i) }
    end
    if (name = params[:name])
      @artists = @artists.select { |item| item[:name].match(/#{name}/i) }
    end

    @artists
  end

  bm.report('reduction, ad-hoc') do
    Rack::Reducer.call(
      params.dup,
      dataset: Fixtures::DB[:artists],
      filters: [
        ->(genre:) {
          select { |item| item[:genre].match(/#{genre}/i) }
        },
        ->(name:) {
          select { |item| item[:name].match(/#{name}/i) }
        },
      ]
    )
  end

  bm.report('reduction, default') do
    TestReducer.call(params.dup)
  end

  bm.compare!
end
