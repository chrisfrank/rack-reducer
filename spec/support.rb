require 'rack/reducer'
require 'sinatra/base'
require 'json'

# mount Rack::Reducer as middleware, let it filter data into env['rack.reduction'],
# and respond with env['rack.reduciton'].to_json
module MiddlewareTest
  OPTIONS = {
    data: ARTISTS,
    filters: [
      ->(genre:) { select { |item| item[:genre].match(/#{genre}/i) } },
      ->(name:) { select { |item| item[:name].match(/#{name}/i) } }
    ],
  }

  def self.app
    Rack::Builder.new do
      use Rack::Reducer, OPTIONS
      run ->(env) { [200, {}, [env['rack.reduction'].to_json]] }
    end
  end
end

class SinatraTest < Sinatra::Base
  module ArtistsReducer
    def self.call(params)
      Rack::Reducer.call(
        data: Artist.dataset,
        filters: FILTERS,
        params: params,
      )
    end

    FILTERS = [
      ->(genre:) { grep(:genre, "%#{genre}%", case_insensitive: true) },
      ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
    ]
  end

  get '/artists' do
    @artists = ArtistsReducer.call(params)
    @artists.all.to_json
  end
end

