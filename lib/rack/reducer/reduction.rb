# frozen_string_literal: true

require_relative 'refinements'

module Rack
  module Reducer
    # call `reduce` on a params hash, filtering data via lambdas with
    # matching keyword arguments
    class Reduction
      using Refinements # define Proc#required_argument_names, #satisfies?, etc

      def initialize(dataset, *filters)
        @dataset = dataset
        @filters = filters
      end

      # Run +@filters+ against the params argument
      # @param [Hash, ActionController::Parameters, nil] params
      #   a Rack-compatible params hash
      # @return +@dataset+ with the matching filters applied
      def apply(params)
        return @dataset if !params || params.empty?

        symbolized_params = params.to_unsafe_h.symbolize_keys
        @filters.reduce(@dataset) do |data, filter|
          next data unless filter.satisfies?(symbolized_params)

          data.instance_exec(
            **symbolized_params.slice(*filter.all_argument_names),
            &filter
          )
        end
      end
    end
  end
end
