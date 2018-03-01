# frozen_string_literal: true

require 'rack/request'
require_relative 'reducer/reduction'

module Rack
  # use request params to apply filters to a dataset
  module Reducer
    # call Rack::Reducer as a function, instead of mounting it as middleware
    def self.call(params, dataset:, filters:)
      Reduction.new(
        nil, # first arg to Reduction is `app`, which is for middleware only
        params: params,
        filters: filters,
        dataset: dataset,
      ).reduce
    end

    def self.new(app, options = {})
      Reduction.new(app, options)
    end

    # extend Rack::Reducer to get `reduce` and `reduces` as class-methods
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
        nil,
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
