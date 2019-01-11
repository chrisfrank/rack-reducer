require_relative 'refinements'
require_relative 'parser'

module Rack
  module Reducer
    # call `reduce` on a params hash, filtering data via lambdas with
    # matching keyword arguments
    class Reduction
      using Refinements # define Proc#required_argument_names, #satisfies?, etc

      DEFAULTS = {
        dataset: [],
        filters: [],
        params: nil
      }.freeze

      def initialize(options)
        @props = DEFAULTS.merge(options)
        @params = Parser.call(@props[:params])
      end

      def reduce
        @props[:filters].reduce(@props[:dataset]) do |data, filter|
          next data unless filter.satisfies?(@params)

          data.instance_exec(@params.slice(*filter.all_argument_names), &filter)
        end
      end
    end

    private_constant :Reduction
  end
end
