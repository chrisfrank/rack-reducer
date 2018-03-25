# frozen_string_literal: true

require 'rack/request'
require_relative 'reducer/reduction'
require_relative 'reducer/middleware'

module Rack
  # Use request params to apply filters to a dataset
  module Reducer
    # Call Rack::Reducer as a function
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

    # Extend Rack::Reducer to get `reduce` and `reduces` as class-methods
    #
    # class Artist < SomeORM::Model
    #   extend Rack::Reducer
    #   reduces self.all, filters: [
    #     lambda { |name:| where(name: name) },
    #     lambda { |genre:| where(genre: genre) },
    #   ]
    # end
    def reduce(params)
      Reduction.new(
        params: params,
        filters: @rack_reducer_filters,
        dataset: @rack_reducer_dataset
      ).reduce
    end

    def reduces(dataset, filters:)
      @rack_reducer_dataset = dataset
      @rack_reducer_filters = filters
    end
  end
end
