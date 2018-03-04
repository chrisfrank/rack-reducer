require 'spec_helper'
require_relative 'fixtures'
require 'sinatra/base'
require 'json'
require 'benchmark/ips'

class App < Sinatra::Base
  get '/conditionals' do
    @artists = DB[:artists]
    if (genre = params[:genre])
      @artists = @artists.grep(:genre, "%#{genre}%", case_insensitive: true)
    end
    if (name = params[:name])
      @artists = @artists.grep(:name, "%#{name}%", case_insensitive: true)
    end

    @artists.to_json
  end

  get '/reduction' do
    @artists = Rack::Reducer.call(params, dataset: DB[:artists], filters: [
      ->(genre:) { grep(:genre, "%#{genre}%", case_insensitive: true) },
      ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
    ])

    @artists.to_json
  end
end

describe 'Performance' do
  let(:app) { App }

  it 'compares favorably to spaghetti code when params are empty' do
    Benchmark.ips(3) do |bm|
      bm.report('conditionals, empty params') do
        get '/conditionals'
      end
      bm.report('reduction, empty params') do
        get '/reduction'
      end
      bm.compare!
    end
  end

  it 'compares favorably to spaghetti code when params are full' do
    Benchmark.ips(3) do |bm|
      bm.report('conditionals, full params') do
        get '/conditionals?name=blake&genre=electronic'
      end
      bm.report('reduction, full params') do
        get '/reduction?name=blake&genre=electronic'
      end
      bm.compare!
    end
  end
end
