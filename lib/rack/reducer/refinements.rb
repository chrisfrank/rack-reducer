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
    end

    private_constant :Refinements
  end
end
