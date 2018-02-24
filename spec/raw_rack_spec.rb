require 'spec_helper'

describe 'Rack::Reducer as a standalone Rack app' do
  let(:app) { Rack::Reducer.new(Artist.all, FILTERS) }

  describe 'filtering' do
    it 'responds with status 200' do
      get('/') { |response| expect(response.status).to eq(200) }
    end

    it 'filters data via params' do
      get('/artists?name=Blake') do |response|
        expect(response.body).to include('Blake Mills')
      end

      get('/artists?genre=electronic') do |response|
        expect(response.body).to include('Björk')
      end
    end

    it 'chains filters when passed multiple params' do
      get('/artists?genre=electronic&name=blake') do |response|
        expect(response.body).to include('James Blake')
        expect(response.body).not_to include('Blake Mills')
      end
    end
  end
end
