module Rack
  # refine core classes in this module only
  module Reducible
    refine Hash do
      def symbolize_keys
        each_with_object({}) do |(key, val), hash|
          hash[key.to_sym] = val.is_a?(Hash) ? val.symbolize_keys : val
        end
      end
    end

    refine Proc do
      def required_args
        parameters.select { |arg| arg[0] == :keyreq }.map(&:last).to_set
      end

      def args
        parameters.map(&:last)
      end
    end
  end
end
