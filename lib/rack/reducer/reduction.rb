# frozen_string_literal: true

require_relative 'refinements'
require_relative 'parser'

module Rack
  module Reducer
    # call `reduce` on a params hash, filtering data via lambdas with
    # matching keyword arguments
    class Reduction
      using Refinements # augment Hash & Proc inside this scope

      DEFAULTS = {
        dataset: [],
        filters: [],
        params: nil
      }.freeze

      def initialize(options)
        @props = DEFAULTS.merge(options)
        @params = Parser.call(@props[:params]).symbolize_keys
      end

      def reduce
        @props[:filters].reduce(@props[:dataset], &method(:apply_filter))
      end

      private

      def apply_filter(data, fn)
        requirements = fn.required_argument_names.to_set
        return data unless @params.satisfies?(requirements)
        data.instance_exec(@params.slice(*fn.all_argument_names), &fn)
      end
    end
  end
end
