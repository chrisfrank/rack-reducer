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

      def self.reduce(params)
        Rack::Reducer.call(
          data: dataset,
          filters: [
            ->(genre:) { grep(:genre, "%#{genre}%", case_insensitive: true) },
            ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
          ],
          params: params,
        )
      end
    end

    ARTISTS.each { |artist| Artist.create(artist) }

    get '/artists' do
      @artists = Artist.reduce(params)
      @artists.all.to_json
    end
end


describe SinatraTest do
  it_behaves_like Rack::Reducer
end
