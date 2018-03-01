# frozen_string_literal: true

require_relative 'refinements'
require_relative 'parser'

module Rack
  module Reducer
    # apply filter functions to a reducible dataset
    class Reduction
      using Refinements

      DEFAULTS = {
        data: [],
        filters: [],
        key: 'rack.reduction',
        params: nil
      }.freeze

      def initialize(app, props)
        @app = app
        @props = DEFAULTS.merge(props)
      end

      def call(env)
        @params = Rack::Request.new(env).params.symbolize_keys
        @app.call env.merge(@props[:key] => reduce)
      end

      def reduce
        @props[:filters].reduce(@props[:data], &method(:apply_filter))
      end

      private

      def params
        @params ||= Parser.call(@props[:params]).symbolize_keys
      end

      def apply_filter(data, fn)
        requirements = fn.required_argument_names.to_set
        return data unless params.satisfies?(requirements)
        data.instance_exec(params.slice(*fn.all_argument_names), &fn)
      end
    end
  end
end
