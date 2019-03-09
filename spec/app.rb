require 'rack/request'

module App
  DB = {
    artists: [
      { name: 'Blake Mills', genre: 'alternative', release_count: 3 },
      { name: 'Björk', genre: 'electronic', release_count: 3 },
      { name: 'James Blake', genre: 'electronic', release_count: 3 },
      { name: 'Janelle Monae', genre: 'alt-soul', release_count: 3 },
      { name: 'SZA', genre: 'alt-soul', release_count: 3 },
      { name: 'Chris Frank', genre: 'alt-soul', release_count: nil },
    ]
  }

  FILTERS = [
    ->(genre:) {
      select { |item| item[:genre].match(/#{genre}/i) }
    },
    ->(name:) {
      select { |item| item[:name].match(/#{name}/i) }
    },
    ->(sort:) {
      sort_by { |item| item[sort.to_sym] }
    },
    ->(releases:) {
      select { |item| item[:release_count].to_i == releases.to_i }
    },
  ]

  ArtistReducer = Rack::Reducer.create(DB[:artists], *FILTERS)

  def self.call(env)
    req = Rack::Request.new(env)
    res = ArtistReducer.call(req.params).to_json
    [200, { 'Content-Type' => 'application/json' }, [res]]
  end
end
