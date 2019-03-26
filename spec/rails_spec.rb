require 'spec_helper'
require_relative 'fixtures'
require 'action_controller/railtie'
require 'securerandom'

class RailsApp < Rails::Application
  routes.append do
    get "/", to: "artists#index"
  end

  config.api_only = true
  config.eager_load = true
  config.secret_key_base = SecureRandom.hex(64)
end

class ArtistsController < ActionController::API
  def index
    @artists = Fixtures::ArtistReducer.call(params)
    render json: @artists
  end
end

RSpec.describe RailsApp do
  let(:app) { RailsApp.initialize! }

  it 'works with the deafult Rails params hash' do
    get('/') { |res| expect(res.status).to eq(200) }
  end
end
