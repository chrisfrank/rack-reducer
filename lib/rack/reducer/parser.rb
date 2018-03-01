# frozen_string_literal: true

module Rack
  module Reducer
    # convert params from Sinatra, Rails, Roda, etc into a symbol hash
    module Parser
      def self.call(data)
        data.is_a?(Hash) ? data : hashify(data)
      end

      # turns out a Rails params hash is not really a hash
      # it's safe to call .to_unsafe_hash here, because params
      # are automatically sanitized by the lambda keywords
      def self.hashify(data)
        fn = %i[to_unsafe_h to_h].find { |name| data.respond_to?(name) }
        data.send(fn)
      end
    end
  end
end
