# frozen_string_literal: true

module Rack
  module Reducer
    # refine a few core classes in Rack::Reducer's scope only
    module Refinements
      refine Hash do
        def symbolize_keys
          each_with_object({}) do |(key, val), hash|
            hash[key.to_sym] = val.is_a?(Hash) ? val.symbolize_keys : val
          end
        end

        def satisfies?(requirements)
          !requirements.empty? &&
            slice(*requirements).keys.to_set == requirements
        end
      end

      refine Proc do
        def required_argument_names
          parameters.select { |arg| arg[0] == :keyreq }.map(&:last)
        end

        def all_argument_names
          parameters.map(&:last)
        end
      end
    end
  end
end
