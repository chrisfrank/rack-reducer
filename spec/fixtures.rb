require 'sequel'

# hash fixture data
ARTISTS = [
  { name: 'Blake Mills', genre: 'alternative' },
  { name: 'Björk', genre: 'electronic' },
  { name: 'James Blake', genre: 'electronic' },
  { name: 'Janelle Monae', genre: 'alt-soul' },
  { name: 'SZA', genre: 'alt-soul' },
].freeze

DB = Sequel.sqlite

DB.create_table :artists do
  String :name
  String :genre
end

class Artist < Sequel::Model
  plugin :json_serializer
end

# that same fixture data, in a SQLite database
ARTISTS.each { |artist| Artist.create(artist) }

