Rack::Reducer
==========================================
Safely map URL params to database filters, in any Rack app. If your users need
to filter data by making HTTP requests, this gem can help.

If you're working in Rails, note that Rack::Reducer solves the same problem
as [Platformatec][1]’s excellent [HasScope][2]. Unlike HasScope, Rack::Reducer
works in any Rack app, with any ORM, or without an ORM at all. Even in Rails,
Reducer's simpler, more functional API may be a better fit for your needs.

Install
------------------------------------------
Add `rack-reducer` to your Gemfile:

```ruby
gem 'rack-reducer', require: 'rack/reducer'
```

Use
------------------------------------------
Rack::Reducer maps incoming URL params to an array of filter functions you
define, chains the applicable filters, and returns filtered data.

Suppose you have some incoming requests like these...

`GET /artists`  
`GET /artists?name=SZA`  
`GET /artists?name=blake&genre=electronic`

You want to filter your `artists` table by name and/or genre when those
params are present, or return all artists otherwise. Rack::Reducer lets you do
just that, in your choice of two styles.

### Mixin-style
You can use Rack::Reducer as a mixin on your models:

```ruby
# app/models/artist.rb

class Artist < ActiveRecord::Base
  extend Rack::Reducer
  # Artist is an ActiveRecord, so filters use ActiveRecord queries
  reduces self.all, filters: [
    ->(name:) { where('lower(name) like ?', "%#{name.downcase}%") },
    ->(genre:) { where(genre: genre) }
  ]
end
```

And call `Model.reduce(params)` in your controllers:

```ruby
# app/controllers/artists_controller.rb

class ArtistsController < ApplicatonController
  def index
    @artists = Artist.reduce(params)
    @artists.to_json
  end
end

# GET /artists returns e.g.
# [
#   { "name": "Blake Mills", "genre": "alternative" },
#   { "name": "Björk", "genre": "electronic" },
#   { "name": "James Blake", "genre": "electronic" },
#   { "name": "Janelle Monae", genre: "alt-soul" },
#   { "name": "SZA", genre: "alt-soul" }
# ]

# GET /artists?name=blake
# returns e.g.
# [
#   { "name": "Blake Mills", "genre": "alternative" },
#   { "name": "James Blake", "genre": "electronic" }
# ]

# GET /artists?name=blake&genre=electronic
# returns e.g. [{ "name": "James Blake", "genre": "electronic" }]
```

### Functional style
Alternatively, you can call Rack::Reducer as a function:

```ruby
# sinatra_functional_example.rb

class App < Sinatra::Base
  DB = Sequel.connect ENV["DATABASE_URL"]

  # This example uses Sequel, so filters use Sequel query methods
  get '/artists' do
    @artists = Rack::Reducer.call(params, dataset: DB[:artists], filters: [
      ->(name:) { grep(:name, "%#{name}%, case_insensitive: true) },
      ->(genre:) { where(genre: genre) }
    ])
    @artists.to_json
  end
end

# GET /artists?name=blake
# returns e.g.
# [
#   { "name": "Blake Mills", "genre": "alternative" },
#   { "name": "James Blake", "genre": "electronic" }
# ]

# GET /artists?name=blake&genre=electronic
# returns e.g. [{ "name": "James Blake", "genre": "electronic" }]
```

The mixin style requires less boilerplate, and is stylistically Railsier.
The functional style is more powerful. Both styles are tested and supported.

The functional style helps make explicit what Rack::Reducer actually does: it
calls [reduce][reduce] on an array of lambdas, `:filters`, with an initial
value of `:dataset`.

Each reduction looks for keys in the params hash that match the
current lambda's [keyword arguments][keywords]. If the keys exist, it
`instance_exec`s the lambda against the dataset, with just those keys as
arguments. Then it passes the filtered dataset on to the next lambda.

Lambdas that don't find all their keyword arguments in `params` don't execute
at all, and pass the dataset down the chain just as they received it.

Framework-specific Examples
---------------------------
These examples apply Rack::Reducer in different frameworks, with a different
ORM each time. The pairings of ORMs and frameworks are abitrary, just to show
a few possible stacks. Rack::Reducer should work on whichever Rack-compatible
stack you like.

- [Sinatra](#sinatrasequelmodel)
- [Roda](#rodasequeldataset)
- [Rack Middleware](#rack-middlewarehash)
- [Rails](#rails)

### Sinatra/Sequel::Model
TODO

### Roda/Sequel::Dataset
TODO

### Rack Middleware/Hash
TODO

### Rails
TODO

How Rack::Reducer Works
-----------------------
TODO

Contributing
------------
TODO


[1]: http://plataformatec.com.br/
[2]: https://github.com/plataformatec/has_scope
[sinatra]: https://github.com/sinatra/sinatra
[sequel]: https://github.com/jeremyevans/sequel
[reduce]: http://ruby-doc.org/core-2.5.0/Enumerable.html#method-i-reduce
[keywords]: https://robots.thoughtbot.com/ruby-2-keyword-arguments
