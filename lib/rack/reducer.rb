require_relative 'reducer/reduction'
require_relative 'reducer/middleware'

module Rack
  # Use request params to apply filters to a dataset
  module Reducer
    # Create a Reducer that can run the @filters against @dataset
    # @param [Object] A dataset, e.g. a Model or Enumerable
    # @param [Array<Proc>] Lambdas with keyword arguments
    def self.create(dataset, *filters)
      Reduction.new(dataset, *filters)
    end

    # Filter a dataset without creating a Reducer first.
    # Note that this approach is a bit slower and less memory-efficient than
    # creating a Reducer via ::create. Use ::create when you can.
    #
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
      Reduction.new(dataset, *filters).call(params)
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
      reducer = Reduction.new(dataset, *filters)
      define_singleton_method :reduce do |params|
        reducer.call(params)
      end
    end
  end
end
