shared_examples_for Rack::Reducer do
  let(:app) { described_class }

  it 'responds with unfiltered data when filter params are empty' do
    get('/artists') do |res|
      ARTISTS.each { |artist| expect(res.body).to include(artist[:name]) }
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
end
