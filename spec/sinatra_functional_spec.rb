require 'spec_helper'
require_relative 'fixtures'
require 'sinatra/base'
require 'json'

class SinatraFunctional < Sinatra::Base
  class Artist < Sequel::Model
    plugin :json_serializer
  end

  get '/artists' do
    @artists = Rack::Reducer.call(params, dataset: Artist, filters: [
      ->(genre:) { grep(:genre, "%#{genre}%", case_insensitive: true) },
      ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
      ->(order: 'genre') { order(order.to_sym) }
    ])

    @artists.all.to_json
  end
end

describe SinatraFunctional do
  let(:app) { described_class }
  it_behaves_like Rack::Reducer

  it 'applies a default order' do
    get '/artists' do |response|
      genre = JSON.parse(response.body).dig(0, 'genre')
      expect(genre).to eq('alt-soul')
    end
  end
end
