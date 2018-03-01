require 'spec_helper'
require_relative 'fixtures'
require 'sinatra/base'
require 'json'
require 'sequel'

class SinatraTest < Sinatra::Base
  DB = Sequel.sqlite

  DB.create_table :artists do
    String :name
    String :genre
  end

  class Artist < Sequel::Model
    plugin :json_serializer
    extend Rack::Reducer
    reduces dataset, via: [
      ->(genre:) { grep(:genre, "%#{genre}%", case_insensitive: true) },
      ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
    ]

  end

  ARTISTS.each { |artist| Artist.create(artist) }

  get '/artists' do
    @artists = Artist.reduce(params)
    @artists.to_json
  end
end

describe SinatraTest do
  it_behaves_like Rack::Reducer

  context 'performance' do
    it 'behaves comparably to hand-filtering params'
  end
end
