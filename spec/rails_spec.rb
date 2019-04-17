require 'spec_helper'
require_relative 'fixtures'

Process.respond_to?(:fork) && RSpec.describe('in a Rails app') do
  BuildRailsApp = lambda do
    require 'action_controller/railtie'
    require 'securerandom'
    app = Class.new(Rails::Application) do
      routes.append do
        get "/", to: "artists#index"
        get "/query", to: "artists#query"
      end

      config.api_only = true
      config.eager_load = true
      config.secret_key_base = SecureRandom.hex(64)
    end

    ArtistsController = Class.new(ActionController::API) do
      def index
        @artists = Fixtures::ArtistReducer.apply(params)
        render json: @artists
      end

      def query
        @artists = Fixtures::ArtistReducer.apply(request.query_parameters)
        render json: @artists
      end
    end

    app.initialize!
  end

  let(:app) { BuildRailsApp.call }

  it 'works with ActionController::Parameters' do
    pid = Process.fork do
      get('/') { |res| expect(res.status).to eq(200) }
    end
    Process.wait pid
  end

  it 'works with request.query_parameters' do
    pid = Process.fork do
      get('/query') { |res| expect(res.status).to eq(200) }
    end
    Process.wait(pid)
  end

  it 'does not load ActiveSupport into global scope b/c of this spec' do
    expect { ''.blank? }.to raise_error(NoMethodError)
  end
end
