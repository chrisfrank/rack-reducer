require 'spec_helper'
require_relative 'fixtures'
require 'sinatra/base'
require 'json'

class SinatraMixin < Sinatra::Base
  class Artist < Sequel::Model
    plugin :json_serializer
    extend Rack::Reducer
    reduces dataset, filters: [
      ->(genre:) { grep(:genre, "%#{genre}%", case_insensitive: true) },
      ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
    ]

  end

  get '/artists' do
    @artists = Artist.reduce(params)
    @artists.to_json
  end
end

describe SinatraMixin do
  it_behaves_like Rack::Reducer

  context 'performance' do
    it 'behaves comparably to hand-filtering params'
  end
end
