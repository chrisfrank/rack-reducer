require 'spec_helper'
require_relative 'fixtures'

RSpec.describe Rack::Reducer do
  using SpecRefinements

  let(:app) do
    lambda do |env|
      req = Rack::Request.new(env)
      res = Fixtures::ArtistReducer.apply(req.params).to_json
      [200, { 'Content-Type' => 'application/json' }, [res]]
    end
  end

  it 'responds with unfiltered data when filter params are empty' do
    get('/') do |res|
      expect(res.json.count).to eq(Fixtures::DB[:artists].count)
    end
  end

  it 'filters by a single param, e.g. name' do
    get('/artists?name=Blake') do |response|
      expect(response.body).to include('Blake Mills')
      expect(response.body).to include('James Blake')
      expect(response.body).not_to include('SZA')
    end
  end

  it 'resets state between requests' do
    get('/artists?name=Blake')
    get('/artists') do |res|
      expect(res.json.count).to eq(Fixtures::DB[:artists].count)
    end
  end

  it 'filters by a single param, e.g. genre' do
    get('/artists?genre=electronic') do |response|
      expect(response.body).to include('Björk')
      expect(response.body).to include('James Blake')
      expect(response.body).not_to include('Blake Mills')
    end

    get '/artists?genre=soul' do |response|
      expect(response.body).to include('Janelle Monae')
      expect(response.body).not_to include('Björk')
    end
  end

  it 'chains multiple filters' do
    get('/artists?genre=electronic&name=blake') do |response|
      expect(response.body).to include('James Blake')
      expect(response.body).not_to include('Blake Mills')
    end
  end

  it 'handles falsy values' do
    get('/artists?releases=0') do |response|
      expect(response.body).to include('Chris Frank')
      expect(JSON.parse(response.body).length).to eq(1)
    end
  end

  it 'accepts nil as params' do
    expect(Fixtures::ArtistReducer.apply(nil)).to be_truthy
  end

  it 'applies default filters' do
    get '/artists' do |response|
      name = response.json[0]['name']
      expect(name).to eq('Björk')
    end
  end

  it 'can override default params' do
    get '/artists?sort=genre' do |response|
      genre = response.json[0]['genre']
      expect(genre).to eq('alt-soul')
    end
  end

  describe 'ad-hoc style via ::call' do
    let(:params) { { 'genre' => 'electronic', 'name' => 'blake' } }
    it 'works just like the primary style, but slower' do
      result = Rack::Reducer.call(
        params,
        dataset: Fixtures::DB[:artists],
        filters: Fixtures::FILTERS,
      )
      expect(result.count).to eq(1)
      expect(result[0][:name]).to eq('James Blake')
    end
  end

  describe 'mixin-style' do
    before { @warnings = [] }

    let(:model) do
      dataset = Fixtures::DB[:artists].dup
      allow(dataset).to(receive(:warn)) { |msg| @warnings << msg }
      dataset.extend Rack::Reducer
      dataset.reduces dataset, filters: Fixtures::FILTERS
      dataset
    end

    it 'is still supported, but with a deprecation warning' do
      params = { 'genre' => 'electronic', 'name' => 'blake' }
      expect(model.reduce(params).count).to eq(1)
      expect(@warnings.first).to include('mixin-style is deprecated')
    end
  end
end
