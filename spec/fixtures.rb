# hash fixture data
ARTISTS = [
  { name: 'Blake Mills', genre: 'alternative' },
  { name: 'Björk', genre: 'electronic' },
  { name: 'James Blake', genre: 'electronic' },
  { name: 'Janelle Monae', genre: 'alt-soul' },
  { name: 'SZA', genre: 'alt-soul' },
].freeze

require 'sequel'
DB = Sequel.sqlite

DB.create_table :artists do
  String :name
  String :genre
end

# put the hash fixtures into an in-memory SQLite database
ARTISTS.each { |artist| DB[:artists].insert(artist) }
