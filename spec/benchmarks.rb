require 'rspec'
require 'rack/reducer'
require_relative 'spec_helper'
require 'json'
require 'benchmark/ips'
require 'benchmark/memory'
require_relative 'fixtures'

module MockController
  Reducer = Rack::Reducer.create(
    Fixtures::DB[:artists],
    ->(genre:) {
      select { |item| item[:genre].match(/#{genre}/i) }
    },
    ->(name:) {
      select { |item| item[:name].match(/#{name}/i) }
    },
  )

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

  def self.via_preset_reducer(params)
    Reducer.call(params)
  end

  def self.via_ad_hoc_reducer(params)
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
end

%i[ips memory].each do |fn|
  Benchmark.send(fn) do |bm|
    params = { name: 'blake', genre: 'electronic' }

    bm.report('conditionals') do
      MockController.via_conditionals(params.dup)
    end

    bm.report('reduction, ad-hoc') do
      MockController.via_ad_hoc_reducer(params.dup)
    end

    bm.report('reduction, default') do
      MockController.via_preset_reducer(params.dup)
    end

    bm.compare!
  end
end
