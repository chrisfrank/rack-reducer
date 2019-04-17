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
  if env['DEFAULTS']
    @artists = @artists.order(:name)
  end
  Rack::Response.new(@artists).finish
end

TestReducer = Rack::Reducer.create(
  DB[:artists],
  ->(genre:) { where(genre: genre.to_s) },
  ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) }
)
TestReducerWithDefaults = Rack::Reducer.create(
  DB[:artists],
  ->(genre:) { where(genre: genre.to_s) },
  ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
  ->(sort: 'name') { order(sort.to_sym) }
)

reducer_app = lambda do |env|
  params = Rack::Request.new(env).params
  @artists = env['DEFAULTS'] ? TestReducerWithDefaults.apply(params) : TestReducer.apply(params)
  Rack::Response.new(@artists).finish
end

Benchmark.ips do |bm|
  env = {
    'REQUEST_METHOD' => 'GET',
    'PATH_INFO' => '/',
    'rack.input' => StringIO.new(''),
    'DEFAULTS' => false
  }

  query = {
    'QUERY_STRING' => 'name=blake&genre=electronic',
  }

  bm.report('Conditionals (full)') do
    conditional_app.call env.merge(query)
  end

  bm.report('Reducer (full)') do
    reducer_app.call env.merge(query)
  end

  bm.report('Conditionals (empty)') do
    conditional_app.call env.dup
  end

  bm.report('Reducer (empty)') do
    reducer_app.call env.dup
  end

  bm.report('Conditionals (defaults)') do
    conditional_app.call env.merge('DEFAULTS' => true)
  end

  bm.report('Reducer (defaults)') do
    reducer_app.call env.merge('DEFAULTS' => true)
  end

  bm.compare!
end
