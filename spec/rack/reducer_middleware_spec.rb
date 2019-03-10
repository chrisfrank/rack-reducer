require 'spec_helper'
require_relative '../fixtures'

RSpec.describe Rack::Reducer::Middleware do
  using SpecRefinements
  module AppFactory
    def self.create(key: nil, middleware_class: Rack::Reducer::Middleware)
      Rack::Builder.new do
        use(
          middleware_class,
          dataset: Fixtures::DB[:artists],
          filters: Fixtures::FILTERS,
          key: key
        )
        run ->(env) {  [200, {}, [env.to_json]] }
      end
    end
  end

  describe 'without a key set' do
    let(:app) { AppFactory.create }
    it 'responds with unfiltered data when filter params are empty' do
      get('/') do |res|
        reduction = res.json['rack.reduction']
        expect(reduction.count).to eq(Fixtures::DB[:artists].count)
      end
    end

    it 'filters by a single param, e.g. name' do
      get('/artists?name=Blake') do |res|
        reduction = res.body
        expect(reduction).to include('Blake Mills')
        expect(reduction).to include('James Blake')
        expect(reduction).not_to include('SZA')
      end
    end
  end

  describe 'with a custom key' do
    let(:app) { AppFactory.create(key: 'custom_key') }
    it 'stores reducer data at env[custom_key]' do
      get('/') do |res|
        expect(res.json['custom_key'].class).to eq(Array)
      end
    end
  end

  describe 'using Rack::Reducer instead of Rack::Reducer::Middleware' do
    before do
      @warnings = []
      allow(Rack::Reducer).to receive(:warn) do |msg|
        @warnings << msg
      end
    end

    let(:app) { AppFactory.create(middleware_class: Rack::Reducer) }

    it 'emits a deprecation warning' do
      get('/')
      expect(@warnings.last).to include('alias of ::create')
    end
  end
end
