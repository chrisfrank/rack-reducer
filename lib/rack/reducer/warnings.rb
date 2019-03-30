# frozen_string_literal: true

module Rack
  module Reducer
    module Warnings
      MESSAGES = {
        new: [
          'Rack::Reducer.new will become an alias of ::create in v2.',
          'To mount middleware that will still work in 2.0, write',
          '"use Rack::Reducer::Middleware" instead of "use Rack::Reducer"',
        ],
        reduces: [
          'Rack::Reducer’s mixin-style is deprecated and may be removed in v2.',
          'To keep using Rack::Reducer in your models, use a Reducer constant.',
          'class MyModel',
          '  MyReducer = Rack::Reducer.create(dataset, *filter_functions)',
          'end',
          'MyModel::MyReducer.call(params)',
        ]
      }.freeze

      def self.[](key)
        MESSAGES.fetch(key, []).join("\n")
      end
    end
  end
end
