require 'spec_helper'
require 'sinatra/base'
require 'json'

class SinatraMixin < Sinatra::Base
  class Artist < Sequel::Model
    plugin :json_serializer
    extend Rack::Reducer
    reduces dataset, filters: SEQUEL_QUERY[:filters]
  end

  get '/artists' do
    @artists = Artist.reduce(params)
    @artists.all.to_json
  end
end

describe SinatraMixin do
  it_behaves_like Rack::Reducer
end
