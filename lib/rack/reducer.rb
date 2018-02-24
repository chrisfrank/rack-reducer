require 'rack'
require_relative 'reducer/reducible'
require_relative 'reducer/errors'

module Rack
  # Use request params to filter a collection
  class Reducer
    using Reducible

    def initialize(collection, filters)
      @collection = collection
      @filters = filters
      validate
    end

    def validate
      @filters.respond_to?(:reduce) || raise(Errors::Unreducable)
      @filters.all? do |filter|
        filter.respond_to?(:call) || raise(Errors::Uncallable)
      end
    end

    def call(env)
      @env = env
      @_request = Rack::Request.new(env)
      [status, headers, body]
    end

    def body
      reduce.all.to_s
    end

    def status
      200
    end

    def headers
      {}
    end

    def params
      @_request.params
    end

    def reduce
      symbolized_params = params.symbolize_keys
      @filters.reduce(@collection) do |data, fn|
        args = fn.required_args
        params = symbolized_params.slice(*args)
        params.keys.to_set == args ? data.instance_exec(params, &fn) : data
      end
    end
  end
end
