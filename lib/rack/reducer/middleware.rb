# frozen_string_literal: true

require 'rack/request'
require_relative 'reduction'

module Rack
  module Reducer
    # Mount Rack::Reducer as middleware
    # @example A microservice that filters artists
    #   ArtistService = Rack::Builder.new do
    #     use(
    #       Rack::Reducer::Middleware,
    #       dataset: Artist.all,
    #       filters: [
    #         lambda { |name:| where(name: name) },
    #         lambda { |genre:| where(genre: genre) },
    #       ]
    #     )
    #
    #     run ->(env) {  [200, {}, [env['rack.reduction'].to_json]] }
    #   end
    class Middleware
      def initialize(app, options = {})
        @app = app
        @key = options[:key] || 'rack.reduction'
        @reducer = Rack::Reducer.create(options[:dataset], *options[:filters])
      end

      # Call the next app in the middleware stack, with env[key] set
      # to the ouput of a reduction
      def call(env)
        params = Rack::Request.new(env).params
        reduction = @reducer.apply(params)
        @app.call env.merge(@key => reduction)
      end
    end
  end
end
