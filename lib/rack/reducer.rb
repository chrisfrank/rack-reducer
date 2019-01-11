require_relative 'reducer/reduction'
require_relative 'reducer/middleware'

module Rack
  # Use request params to apply filters to a dataset
  module Reducer
    # Filter a dataset
    # @param params [Hash] Rack-compatible URL params
    # @param dataset [Object] A dataset, e.g. one of your App's models
    # @param filters [Array<Proc>] An array of lambdas with keyword arguments
    # @example Call Rack::Reducer as a function in a Sinatra app
    #   ArtistReducer = {
    #     dataset: Artist,
    #     filters: [
    #       lambda { |name:| where(name: name) },
    #       lambda { |genre:| where(genre: genre) },
    #     ]
    #   }
    #   get '/artists' do
    #     @artists = Rack::Reducer.call(params, ArtistReducer)
    #   end
    def self.call(params, dataset:, filters:)
      Reduction.new(
        params: params,
        filters: filters,
        dataset: dataset
      ).reduce
    end

    # Mount Rack::Reducer as middleware
    def self.new(app, options = {})
      Middleware.new(app, options)
    end

    # Extend Rack::Reducer to get +reduce+ and +reduces+ as class-methods
    # @example Make an "Artists" model reducible
    #   class Artist < SomeORM::Model
    #     extend Rack::Reducer
    #     reduces self.all, filters: [
    #       lambda { |name:| where(name: name) },
    #       lambda { |genre:| where(genre: genre) },
    #     ]
    #   end
    #
    #   Artist.reduce(params)
    def reduces(dataset, filters:)
      define_singleton_method :reduce do |params|
        Reduction.new(
          params: params,
          filters: filters,
          dataset: dataset,
        ).reduce
      end
    end
  end
end
