require 'spec_helper'
require_relative '../app'

RSpec.describe Rack::Reducer do
  using Module.new {
    refine Rack::MockResponse do
      define_method(:json) { JSON.parse(body) }
    end
  }

  let(:app) { App }

  it 'responds with unfiltered data when filter params are empty' do
    get('/') do |res|
      expect(res.json.count).to eq(App::DB[:artists].count)
    end
  end

  it 'filters by a single param, e.g. name' do
    get('/artists?name=Blake') do |response|
      expect(response.body).to include('Blake Mills')
      expect(response.body).to include('James Blake')
      expect(response.body).not_to include('SZA')
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

  it 'can sort as well as filter' do
    get '/artists?order=genre' do |response|
      genre = response.json[0]['genre']
      expect(genre).to eq('alternative')
    end
  end

  describe 'ad-hoc style via ::call' do
    it 'is still supported' do
      params = { 'genre' => 'electronic', 'name' => 'blake' }
      result = Rack::Reducer.call(
        params,
        dataset: App::DB[:artists],
        filters: App::FILTERS,
      )
      expect(result.count).to eq(1)
      expect(result[0][:name]).to eq('James Blake')
    end
  end

  describe 'mixin-style' do
    it 'is still supported'
    it 'raises a deprecation warning'
  end
end
