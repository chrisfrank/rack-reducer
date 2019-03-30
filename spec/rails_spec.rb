require 'spec_helper'
require_relative 'fixtures'
require 'action_controller/railtie'
require 'securerandom'

class RailsApp < Rails::Application
  routes.append do
    get "/", to: "artists#index"
    get "/query", to: "artists#query"
  end

  config.api_only = true
  config.eager_load = true
  config.secret_key_base = SecureRandom.hex(64)
end

class ArtistsController < ActionController::API
  def index
    @artists = Fixtures::ArtistReducer.apply(params)
    render json: @artists
  end

  def query
    @artists = Fixtures::ArtistReducer.apply(request.query_parameters)
    render json: @artists
  end
end

RSpec.describe RailsApp do
  let(:app) { RailsApp.initialize! }

  it 'works with ActionController::Parameters and a plain hash' do
    get('/') { |res| expect(res.status).to eq(200) }
    get('/query') { |res| expect(res.status).to eq(200) }
  end
end
