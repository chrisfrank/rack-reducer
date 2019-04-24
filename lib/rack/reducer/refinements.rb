# frozen_string_literal: true

module Rack
  module Reducer
    # refine Proc and hash in this scope only
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
        def symbolize_keys
          each_with_object({}) do |(key, val), hash|
            hash[key.to_sym] = val.is_a?(Hash) ? val.symbolize_keys : val
          end
        end

        alias_method :to_unsafe_h, :to_h
      end
    end

    private_constant :Refinements
  end
end
