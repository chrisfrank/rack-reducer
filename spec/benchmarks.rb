require_relative 'spec_helper'
require 'sinatra/base'
require 'json'
require 'benchmark/ips'

Conditionals = lambda do |params = {}|
  @artists = DB[:artists]
  if (genre = params[:genre])
    @artists = @artists.grep(:genre, "%#{genre}%", case_insensitive: true)
  end
  if (name = params[:name])
    @artists = @artists.grep(:name, "%#{name}%", case_insensitive: true)
  end

  @artists.to_json
end

Reduction = lambda do |params = {}|
  @artists = Rack::Reducer.call(params, dataset: DB[:artists], filters: [
    ->(genre:) { grep(:genre, "%#{genre}%", case_insensitive: true) },
    ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
  ])

  @artists.to_json
end

Benchmark.ips(3) do |bm|
  bm.report('conditionals, empty params') { Conditionals.call }

  bm.report('reduction, empty params') { Reduction.call }

  bm.report('conditionals, full params') do
    Conditionals.call({ name: 'blake', genre: 'electric' })
  end

  bm.report('reduction, full params') do
    Reduction.call({ name: 'blake', genre: 'electric' })
  end

  bm.compare!
end
