require 'rspec'
require 'rack/reducer'
require_relative 'spec_helper'
require 'json'
require 'benchmark/ips'
require_relative 'fixtures'

module MockController
  def self.via_conditionals(params)
    @artists = Fixtures::DB[:artists]
    if (genre = params[:genre])
      @artists = @artists.select { |item| item[:genre].match(/#{genre}/i) }
    end
    if (name = params[:name])
      @artists = @artists.select { |item| item[:name].match(/#{name}/i) }
    end

    @artists
  end
end

Benchmark.ips do |bm|
  params = { name: 'blake', genre: 'electronic' }

  bm.report('conditionals') do
    MockController.via_conditionals(params.dup)
  end

  bm.report('reduction, ad-hoc') do
    Rack::Reducer.call(
      params,
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
    Fixtures::ArtistReducer.call(params)
  end

  bm.compare!
end
