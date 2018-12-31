module Rack
  module Reducer
    # convert params from Sinatra, Rails, Roda, etc into a symbol hash
    module Parser
      def self.call(data)
        data.is_a?(Hash) ? symbolize(data) : hashify(data)
      end

      def self.symbolize(data)
        data.each_with_object({}) do |(key, val), hash|
          hash[key.to_sym] = val.is_a?(Hash) ? symbolize(val) : val
        end
      end

      # turns out a Rails params hash is not really a hash
      # it's safe to call .to_unsafe_hash here, because params
      # are automatically sanitized by the lambda keywords
      def self.hashify(data)
        fn = %i[to_unsafe_h to_h].find { |name| data.respond_to?(name) }
        symbolize(data.send(fn))
      end
    end
  end
end
