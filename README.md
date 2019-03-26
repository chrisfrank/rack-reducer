Rack::Reducer
==========================================
[![Build Status](https://travis-ci.org/chrisfrank/rack-reducer.svg?branch=master)](https://travis-ci.org/chrisfrank/rack-reducer)
[![Maintainability](https://api.codeclimate.com/v1/badges/675e7a654c7e11c24b9f/maintainability)](https://codeclimate.com/github/chrisfrank/rack-reducer/maintainability)

Declaratively filter data via URL params, in any Rack app, with any ORM.

Install
------------------------------------------
Add `rack-reducer` to your Gemfile:

```ruby
gem 'rack-reducer', require: 'rack/reducer'
```

Quickstart
------------------------------------------
If your app needs to render a list of database records, you probably want those
records to be filterable via URL params, like so:

```
GET /artists => all artists
GET /artists?name=blake` => artists named 'blake'
GET /artists?genre=electronic&name=blake => electronic artists named 'blake'
```

Rack::Reducer can help. It applies incoming URL params to an array of filter
functions you define, runs only the relevant filters, and returns your filtered
data. You worry about writing filters, Rack::Reducer worries about when to
apply them.

Here it is in a Rails controller:

```ruby
# app/controllers/artists_controller.rb
class ArtistsController < ApplicationController
  # Step 1: Create a reducer
  ArtistReducer = Rack::Reducer.create(
    Artist.all,
    ->(name:) { where('lower(name) like ?', "%#{name.downcase}%") },
    ->(genre:) { where(genre: genre) },
  )

  # Step 2: Apply it to incoming requests
  def index
    @artists = ArtistReducer.apply(params)
    render json: @artists
  end
end
```

This example app would handle requests as follows:

```ruby
# GET /artists => All artists:
[
  { "name": "Blake Mills", "genre": "alternative" },
  { "name": "Björk", "genre": "electronic" },
  { "name": "James Blake", "genre": "electronic" },
  { "name": "Janelle Monae", "genre": "alt-soul" },
  { "name": "SZA", "genre": "alt-soul" }
]

# GET /artists?name=blake => Artists named "blake":
[
  { "name": "Blake Mills", "genre": "alternative" },
  { "name": "James Blake", "genre": "electronic" }
]

# GET /artists?name=blake&genre=electronic => Electronic artists named "blake"
[{ "name": "James Blake", "genre": "electronic" }]
```

Framework-specific Examples
---------------------------
These examples apply Rack::Reducer in different frameworks and ORMs. The
pairings of ORMs and frameworks are arbitrary, just to demonstrate a few
possible stacks.

### Sinatra/Sequel
This example uses [Sinatra][sinatra] to handle requests, and [Sequel][sequel]
as an ORM.

```ruby
# sinatra_functional_style.rb
class SinatraExample < Sinatra::Base
  DB = Sequel.connect ENV['DATABASE_URL']

  # dataset is a Sequel::Dataset, so filters use Sequel query methods
  ArtistReducer = Rack::Reducer.create(
    DB[:artists],
    ->(genre:) { where(genre: genre) },
    ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
  )

  get '/artists' do
    @artists = ArtistReducer.apply(params).all
    @artists.to_json
  end
end
```

### Rack Middleware/Ruby Array
This example runs a raw Rack app with Rack::Reducer mounted as middleware.
It doesn't use an ORM at all -- it just stores data in a ruby array.

```ruby
# config.ru
require 'rack'
require 'rack/reducer'
require 'json'

ARTISTS = [
  { name: 'Blake Mills', genre: 'alternative' },
  { name: 'Björk', genre: 'electronic' },
  { name: 'James Blake', genre: 'electronic' },
  { name: 'Janelle Monae', genre: 'alt-soul' },
  { name: 'SZA', genre: 'alt-soul' },
]

app = Rack::Builder.new do
  # dataset  is a hash, so filter functions use ruby hash methods
  use Rack::Reducer::Middleware, dataset: ARTISTS, filters: [
    ->(genre:) { select { |item| item[:genre].match(/#{genre}/i) } },
    ->(name:) { select { |item| item[:name].match(/#{name}/i) } },
    ->(sort:) { sort_by { |item| item[sort.to_sym] } },
  ]
  run ->(env) { [200, {}, [env['rack.reduction'].to_json]] }
end

run app
```

When Rack::Reducer is mounted as middleware, it stores its filtered data in
env['rack.reduction'], then calls the next app in the middleware stack. You can
change the `env` key by passing a new name as option to `use`:

```ruby
# config.ru
use Rack::Reducer::Midleware, key: 'custom.key', dataset: ARTISTS, filters: [
  # an array of lambdas
]
```

### Rails Scopes
The Rails [quickstart example](#quickstart) created a reducer inside a
controller, but if your filters use lots of ActiveRecord `scope`s, it might make
more sense to keep your reducers in your models instead.

```ruby
# app/models/artist.rb
class Artist < ApplicationRecord
  # filters get instance_exec'd against the dataset you provide -- in this case
  # it's `self.all` -- so filters can use query methods, scopes, etc
  Reducer = Rack::Reducer.create(
    self.all,
    ->(name:) { by_name(name) },
    ->(genre:) { where(genre: genre) },
    ->(sort:) { order(sort.to_sym) }
  ]

  scope :by_name, lambda { |name|
    where('lower(name) like ?', "%#{name.downcase}%")
  }
end

# app/controllers/artists_controller.rb
class ArtistsController < ApplicationController
  def index
    @artists = Artist::Reducer.apply(params)
    render json: @artists
  end
end
```

### Default filters
Most of the time it makes sense to use *required* keyword arguments for each
filter, and skip running the filter altogether when the keyword argments aren't
present.

But sometimes you'll want to run a filter with a default value, even when the
required params are missing.  The code below will order by `params[:sort]` when
it exists, and by name otherwise.

```ruby
# app/controllers/artists_controller.rb
class ArtistsController < ApplicationController
  ArtistReducer = Rack::Reducer.create(
    Artist.all,
    ->(genre:) { where(genre: genre) },
    ->(sort: 'name') { order(sort.to_sym) }
  )

  def index
    @artists = ArtistReducer.apply(params)
    render json: @artists
  end
end
```

### Calling Rack::Reducer as a function
TODO

How Rack::Reducer Works
--------------------------------------
Rack::Reducer takes a dataset, an array of lambdas, and a params hash.

To return filtered data, it calls Enumerable#[reduce][reduce] on your array of
lambdas, with the reduction's initial value set to `dataset`.

Each reduction looks for keys in the `params` hash that match the
current lambda's [keyword arguments][keywords]. If the keys exist, it
`instance_exec`s the lambda against the dataset, passing just those keys as
arguments, and finally passes the filtered dataset on to the next lambda.

Lambdas that don't find all their required keyword arguments in `params` don't
execute at all, and just pass the unaltered dataset down the chain.

The reason Reducer works with any ORM is that *you* supply the dataset and
filter functions. Reducer doesn't need to know anything about ActiveRecord,
Sequel, Mongoid, etc -- it just `instance_exec`s your own code against your
own dataset.

Performance
---------------------
According to `spec/benchmarks.rb`, Rack::Reducer is about 10% slower than a set
of hard-coded `if` statements. It is unlikely to be a bottleneck in your app.

```
Warming up --------------------------------------
        Conditionals   521.000  i/100ms
             Reducer   433.000  i/100ms
Calculating -------------------------------------
        Conditionals      4.782k (± 2.2%) i/s -     23.966k in   5.013863s
             Reducer      4.358k (± 2.8%) i/s -     22.083k in   5.071282s

Comparison:
        Conditionals:     4782.2 i/s
             Reducer:     4358.1 i/s - 1.10x  slower
```

Alternatives
-------------------
If you're working in Rails, Plataformatec's excellent [HasScope][has_scope] has
been solving this problem since 2009. I prefer keeping my request logic all in
one place, though, instead of spreading it across my controllers and models.

[Periscope][periscope], by laserlemon, seems like another good Rails option, and
though it's Rails only, it supports more than just ActiveRecord.

For Sinatra, Simon Courtois has a [Sinatra port of has_scope][sin_has_scope].
It depends on ActiveRecord.

Contributing
-------------------------------
### Bugs
Please open [an issue](https://github.com/chrisfrank/rack-reducer/issues) on
Github.

### Pull Requests
PRs are welcome, and I'll do my best to review them promptly.

License
----------
### MIT

Copyright 2018 Chris Frank

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



[has_scope]: https://github.com/plataformatec/has_scope
[sin_has_scope]: https://github.com/simonc/sinatra-has_scope
[sinatra]: https://github.com/sinatra/sinatra
[sequel]: https://github.com/jeremyevans/sequel
[reduce]: http://ruby-doc.org/core-2.5.0/Enumerable.html#method-i-reduce
[keywords]: https://robots.thoughtbot.com/ruby-2-keyword-arguments
[periscope]: https://github.com/laserlemon/periscope
