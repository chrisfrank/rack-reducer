# frozen_string_literal: true

require 'rack/request'
require_relative 'reducer/reduction'

module Rack
  # Use request params to filter a collection
  module Reducer
    def self.call(options = {})
      Reduction.new(nil, options).reduce
    end

    def self.new(app = nil, options = {})
      Reduction.new(app, options)
    end

    # extend Rack::Reducer to make the methods below available at class-level.
    #
    # class Artist < ActiveRecord::Base
    #   extend Rack::Reducer
    #   reduces self.all, via: [
    #     lambda { |name:| where(name: name) },
    #     lambda { |genre:| where(genre: genre) },
    #   ]
    # end
    def reduce(params)
      Reduction.new(
        nil,
        params: params,
        filters: @reducer_filters,
        data: @reducer_dataset
      ).reduce
    end

    def reduces(data, via:)
      @reducer_dataset = data
      @reducer_filters = via
    end
  end
end
