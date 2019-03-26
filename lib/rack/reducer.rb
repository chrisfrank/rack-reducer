# frozen_string_literal: true

require_relative 'reducer/reduction'
require_relative 'reducer/middleware'

module Rack
  # Use request params to apply filters to a dataset
  module Reducer
    # Create a Reduction object that can filter a dataset via #apply
    # @param [Object] dataset an ActiveRecord::Relation, Sequel::Dataset,
    #   or other class with chainable methods
    # @param [Array<Proc>] filters  An array of lambdas whose keyword arguments
    #   name the URL params you will use as filters
    # @return Rack::Reducer::Reduction
    # @example Create a reducer and use it in a Sinatra app
    #   DB = Sequel.connect(ENV['DATABASE_URL'])
    #   MyReducer = Rack::Reducer.create(
    #     DB[:artists],
    #     lambda { |name:| where(name: name) },
    #     lambda { |genre:| where(genre: genre) },
    #   )
    #
    #   get '/artists' do
    #     @artists = MyReducer.apply(params)
    #     @artists.to_json
    #   end
    def self.create(dataset, *filters)
      Reduction.new(dataset, *filters)
    end

    # Filter a dataset without creating a Reducer first.
    # Note that this approach is a bit slower and less memory-efficient than
    # creating a Reducer via ::create. Use ::create when you can.
    #
    # @param params [Hash] Rack-compatible URL params
    # @param dataset [Object] A dataset, e.g. one of your App's models
    # @param filters [Array<Proc>] An array of lambdas with keyword arguments
    # @example Call Rack::Reducer as a function in a Sinatra app
    #   get '/artists' do
    #     @artists = Rack::Reducer.call(params, dataset: Artist.all, filters: [
    #       lambda { |name:| where(name: name) },
    #       lambda { |genre:| where(genre: genre) },
    #     ])
    #   end
    def self.call(params, dataset:, filters:)
      Reduction.new(dataset, *filters).apply(params)
    end

    # Mount Rack::Reducer as middleware
    # @deprecated
    #   Rack::Reducer.new will become an alias of ::create in v2.0.
    #   To mount middleware that will still work in 2.0, write
    #   "use Rack::Reducer::Middleware" instead of "use Rack::Reducer"
    def self.new(app, options = {})
      warn <<~WARNING
        #{caller(1..1).first}:
        Rack::Reducer.new will become an alias of ::create in v2.0.
        To mount middleware that will still work in 2.0, write
        "use Rack::Reducer::Middleware" instead of "use Rack::Reducer"
      WARNING
      Middleware.new(app, options)
    end

    # Extend Rack::Reducer to get +reduce+ and +reduces+ as class-methods
    #
    # @example Make an "Artists" model reducible
    #   class Artist < SomeORM::Model
    #     extend Rack::Reducer
    #     reduces self.all, filters: [
    #       lambda { |name:| where(name: name) },
    #       lambda { |genre:| where(genre: genre) },
    #     ]
    #   end
    #   Artist.reduce(params)
    #
    # @deprecated
    #   Rack::Reducer's mixin-style is deprecated and may be removed in 2.0.
    #   To keep using Rack::Reducer in your models, create a Reducer constant.
    #     class MyModel < ActiveRecord::Base
    #       MyReducer = Rack::Reducer.create(dataset, *filter_functions)
    #     end
    #     MyModel::MyReducer.call(params)
    def reduces(dataset, filters:)
      warn <<~WARNING
        #{caller(1..1).first}:
        Rack::Reducer's mixin-style is deprecated and may be removed in 2.0.
        To keep using Rack::Reducer in your models, create a Reducer constant.
        class MyModel
          MyReducer = Rack::Reducer.create(dataset, *filter_functions)
        end
        MyModel::MyReducer.call(params)
      WARNING
      reducer = Reduction.new(dataset, *filters)
      define_singleton_method :reduce do |params|
        reducer.apply(params)
      end
    end
  end
end
