require 'rack'
require 'pry'
require 'json'
require_relative '../lib/rack/reducer'
require 'benchmark/ips'
require_relative 'fixtures'
require 'sequel'

DB = Sequel.sqlite.tap do |db|
  db.create_table(:artists) do
    primary_key :id
    String :name
    String :genre
    Integer :release_count
  end
  Fixtures::DB[:artists].each { |row| db[:artists].insert(row) }
end

conditional_app = lambda do |env|
  params = Rack::Request.new(env).params
  @artists = DB[:artists]
  if (genre = params['genre'])
    @artists = @artists.where(genre: genre.to_s)
  end
  if (name = params['name'])
    @artists = @artists.grep(:name, "%#{name}%", case_insensitive: true)
  end
  Rack::Response.new(@artists).finish
end

TestReducer = Rack::Reducer.create(
  DB[:artists],
  ->(genre:) { where(genre: genre.to_s) },
  ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
)

reducer_app = lambda do |env|
  params = Rack::Request.new(env).params
  @artists = TestReducer.apply(params)
  Rack::Response.new(@artists).finish
end

Benchmark.ips do |bm|
  env = {
    'REQUEST_METHOD' => 'GET',
    'PATH_INFO' => '/',
    'QUERY_STRING' => 'name=blake&genre=electronic',
    'rack.input' => StringIO.new('')
  }

  bm.report('Conditionals') do
    conditional_app.call(env.dup)
  end

  bm.report('Reducer') do
    reducer_app.call(env.dup)
  end

  bm.compare!
end
