require 'spec_helper'
require_relative 'fixtures'

Process.respond_to?(:fork) && RSpec.describe('in a Rails app') do
  using SpecRefinements
  BuildRailsApp = lambda do
    require 'action_controller/railtie'
    require 'active_record'
    require 'securerandom'
    require 'sqlite3'

    app = Class.new(Rails::Application) do
      routes.append do
        get "/", to: "artists#index"
        get "/query", to: "artists#query"
      end

      config.api_only = true
      config.eager_load = true
      config.secret_key_base = SecureRandom.hex(64)
    end

    ActiveRecord::Base.establish_connection("sqlite3::memory:")
    ActiveRecord::Schema.define do
      create_table :artists do |t|
        t.string  :name
        t.string  :genre
        t.integer  :release_count
      end
    end

    Artist = Class.new(ActiveRecord::Base)

    Fixtures::DB[:artists].each { |row|Artist.create(row) }

    ArtistsController = Class.new(ActionController::API) do
      RailsReducer = Rack::Reducer.new(
        Artist.all,
        ->(name:) { where('lower(name) like ?', "%#{name.downcase}%") },
        ->(genre:) { where(genre: genre) },
      )

      def index
        @artists = RailsReducer.apply(params)
        render json: @artists
      end

      def query
        @artists = RailsReducer.apply(request.query_parameters)
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

  it 'tracks updates to the backend between requests' do
    pid = Process.fork do
      res = get("/query?name=ZA")
      expect(res.json.count).to eq(1)

      Artist.create!(name: "RZA", genre: "hip hop")

      res = get("/query?name=ZA")
      expect(res.json.count).to eq(2)

      Artist.find_by(name: "RZA").destroy

      get("/query?name=ZA") { |res| expect(res.json.count).to eq(1) }
    end
    Process.wait(pid)
  end

  it 'does not pollute the global Ruby scope' do
    expect { ''.blank? }.to raise_error(NoMethodError)
  end
end
