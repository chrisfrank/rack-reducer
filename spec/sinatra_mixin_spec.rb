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
      ->(order:) { order(order.to_sym) }
    ]

  end

  get '/artists' do
    @artists = Artist.reduce(params)
    @artists.all.to_json
  end
end

describe SinatraMixin do
  it_behaves_like Rack::Reducer
end
