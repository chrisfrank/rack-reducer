require 'spec_helper'
require_relative 'fixtures'
require 'sinatra/base'
require 'json'

class SinatraFunctional < Sinatra::Base
  class Artist < Sequel::Model
    plugin :json_serializer
  end

  get '/artists' do
    @artists = Rack::Reducer.call(
      params,
      dataset: Artist,
      filters: [
        ->(genre:) { grep(:genre, "%#{genre}%", case_insensitive: true) },
        ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
      ]
    )

    @artists.to_json
  end
end

describe SinatraFunctional do
  it_behaves_like Rack::Reducer

  context 'performance' do
    it 'behaves comparably to hand-filtering params'
  end
end
