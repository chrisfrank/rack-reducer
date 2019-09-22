require 'spec_helper'
require_relative 'fixtures'

RSpec.describe 'Rack::Reducer' do
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

  describe 'between requests' do
    original_count = Fixtures::DB[:artists].count

    it 'resets filter state' do
      get('/artists?name=Blake')
      get('/artists') do |res|
        expect(res.json.count).to eq(Fixtures::DB[:artists].count)
      end
    end

    it 'tracks updates to the backend' do
      get('/artists')

      Fixtures::DB[:artists][0][:name] = "Lizzo"
      Fixtures::DB[:artists] << { name: 'New Artist' }

      get('/artists') do |response|
        expect(response.json.count).to eq(original_count + 1)
        expect(response.json.dig(0, 'name')).to eq('Lizzo')
      end

      Fixtures::DB[:artists].pop
      Fixtures::DB[:artists][0][:name] = "Blake Mills"
    end
  end

  describe 'with default filters' do
    let(:app) do
      sort = ->(sort: 'name') { sort_by { |item| item[sort.to_sym] }  }
      filters = Fixtures::FILTERS + [sort]
      reducer = Rack::Reducer.new(Fixtures::DB[:artists], *filters)

      lambda do |env|
        req = Rack::Request.new(env)
        res = reducer.apply(req.params).to_json
        [200, { 'Content-Type' => 'application/json' }, [res]]
      end
    end

    it 'applies default filters' do
      get '/artists' do |response|
        name = response.json[0]['name']
        expect(name).to eq('Björk')
      end
    end

    it 'overrides default filters with values from params' do
      get '/artists?sort=genre' do |response|
        genre = response.json[0]['genre']
        expect(genre).to eq('alt-soul')
      end
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

  it 'aliases ::create and ::new' do
    expect(Rack::Reducer.create({}, -> { 'hi' })).to be_a(Rack::Reducer)
  end

  it 'accepts nested params' do
    get('/artists?range[min]=1&range[max]=100') do |response|
      expect(response.status).to eq(200)
    end
  end
end
