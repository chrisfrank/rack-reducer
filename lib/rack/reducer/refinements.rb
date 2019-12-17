# frozen_string_literal: true

module Rack
  class Reducer
    # Refine a few core classes in Rack::Reducer's scope only
    module Refinements
      refine Proc do
        def required_argument_names
          parameters.select { |type, _| type == :keyreq }.map(&:last)
        end

        def all_argument_names
          parameters.map(&:last)
        end

        def satisfies?(params)
          keywords = required_argument_names
          params.slice(*keywords).keys.to_set == keywords.to_set
        end
      end

      # backport Hash#slice for Ruby < 2.4
      unless {}.respond_to?(:slice)
        refine Hash do
          def slice(*keys)
            [keys, values_at(*keys)].transpose.select { |_k, val| val }.to_h
          end
        end
      end

      refine Hash do
        def deep_symbolize_keys
          each_with_object({}) do |(key, val), hash|
            hash[key.to_sym] = val.is_a?(Hash) ? val.deep_symbolize_keys : val
          end
        end

        alias_method :to_unsafe_h, :to_h
      end

      refine NilClass do
        def empty?
          true
        end
      end
    end

    private_constant :Refinements
  end
end
