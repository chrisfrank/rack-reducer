# frozen_string_literal: true

require_relative 'reducer/refinements'
require_relative 'reducer/middleware'

module Rack
  # Declaratively filter data via URL params, in any Rack app, with any ORM.
  class Reducer
    using Refinements

    class << self
      # make ::create an alias of ::new, for compatibility with v1
      alias create new

      # Call Rack::Reducer as a function instead of creating a named reducer
      def call(params, dataset:, filters:)
        new(dataset, *filters).apply(params)
      end
    end

    # Instantiate a Reducer that can filter `dataset` via `#apply`.
    # @param [Object] dataset an ActiveRecord::Relation, Sequel::Dataset,
    #   or other class with chainable methods
    # @param [Array<Proc>] filters  An array of lambdas whose keyword arguments
    #   name the URL params you will use as filters
    # @example Create a reducer and use it in a Sinatra app
    #   DB = Sequel.connect(ENV['DATABASE_URL'])
    #
    #   MyReducer = Rack::Reducer.new(
    #     DB[:artists],
    #     lambda { |name:| where(name: name) },
    #     lambda { |genre:| where(genre: genre) },
    #   )
    #
    #   get '/artists' do
    #     @artists = MyReducer.apply(params)
    #     @artists.to_json
    #   end
    def initialize(dataset, *filters)
      @dataset = dataset
      @filters = filters
      @default_filters = filters.select do |filter|
        filter.required_argument_names.empty?
      end
    end

    # Run `@filters` against `url_params`
    # @param [Hash, ActionController::Parameters, nil] url_params
    #   a Rack-compatible params hash
    # @return `@dataset` with the matching filters applied
    def apply(url_params)
      if url_params.empty?
        # Return early with the unfiltered dataset if no default filters exist
        return fresh_dataset if @default_filters.empty?

        # Run only the default filters
        filters, params = @default_filters, EMPTY_PARAMS
      else
        # This request really does want filtering; run a full reduction
        filters, params = @filters, url_params.to_unsafe_h.deep_symbolize_keys
      end

      reduce(params, filters)
    end

    private

    def reduce(params, filters)
      filters.reduce(fresh_dataset) do |data, filter|
        next data unless filter.satisfies?(params)

        data.instance_exec(
          **params.slice(*filter.all_argument_names),
          &filter
        )
      end
    end

    # Rails +Model.all+ relations get query-cached by default, which has caused
    # filterless requests to load stale data. This method busts the query cache.
    # See https://github.com/chrisfrank/rack-reducer/issues/11
    def fresh_dataset
      @dataset.clone
    end

    EMPTY_PARAMS = {}.freeze
    private_constant :EMPTY_PARAMS
  end
end
