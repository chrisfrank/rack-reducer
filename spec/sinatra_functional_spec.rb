require 'spec_helper'
require 'sinatra/base'
require 'json'

class SinatraFunctional < Sinatra::Base
  class Artist < Sequel::Model
    plugin :json_serializer
  end

  get '/artists' do
    @artists = Rack::Reducer.call(params, SEQUEL_QUERY)
    @artists.to_a.to_json
  end
end

describe SinatraFunctional do
  let(:app) { described_class }
  it_behaves_like Rack::Reducer

  it 'applies a default order' do
    get '/artists' do |response|
      genre = JSON.parse(response.body)[0]['genre']
      expect(genre).to eq('alt-soul')
    end
  end
end
