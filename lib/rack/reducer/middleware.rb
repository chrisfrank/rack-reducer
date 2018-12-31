require 'rack/request'
require_relative 'reduction'

module Rack
  module Reducer
    # Mount Rack::Reducer as middleware
    class Middleware
      def initialize(app, options = {})
        @app = app
        @key = options[:key] || 'rack.reduction'
        @props = options
      end

      # Call the next app in the middleware stack, with env[key] set
      # to the ouput of a reduction
      def call(env)
        params = Rack::Request.new(env).params
        reduction = Reduction.new(@props.merge(params: params)).reduce
        @app.call env.merge(@key => reduction)
      end
    end
  end
end
