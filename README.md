Rack::Reducer
==========================================
[![Build Status](https://travis-ci.org/chrisfrank/rack-reducer.svg?branch=master)](https://travis-ci.org/chrisfrank/rack-reducer)
[![Maintainability](https://api.codeclimate.com/v1/badges/675e7a654c7e11c24b9f/maintainability)](https://codeclimate.com/github/chrisfrank/rack-reducer/maintainability)

Dynamically filter and sort data via URL params, with controller logic as
succint as

```ruby
@artists = Artist.reduce(params)
```

Rack::Reducer works in any Rack-compatible app, with any ORM, and has no
dependencies beyond Rack itself.

Install
------------------------------------------
Add `rack-reducer` to your Gemfile:

```ruby
gem 'rack-reducer', require: 'rack/reducer'
```

Use
------------------------------------------
If your app needs to render a list of database records, you probably want those
records to be filterable via URL params, like so:

```
GET /artists?name=blake` => artists named 'blake'
GET /artists?genre=electronic&sort=name => electronic artists, sorted by name
GET /artists => all artists
```

You _could_ conditionally apply filters with hand-written `if` statements, but
that approach gets uglier the more filters you have.

Rack::Reducer can help. It maps incoming URL params to an array of filter
functions you define, applies only the applicable filters, and returns your
filtered data.

You can use Rack::Reducer in your choice of two styles: **mixin** or
**functional**.

### Mixin style
Call `Model.reduce(params)` in your controllers...

```ruby
# app/controllers/artists_controller.rb
class ArtistsController < ApplicationController
  def index
    @artists = Artist.reduce(params)
    render json: @artists
  end
end
```

...and `extend Rack::Reducer` in your models:

```ruby
# app/models/artist.rb
class Artist < ActiveRecord::Base
  extend Rack::Reducer

  # Configure by calling
  # `reduces(some_initial_scope, filters: [an, array, of, lambdas])`
  #
  # Filters can use any methods your initial dataset understands,
  # in this case Artist class methods and scopes
  reduces self.all, filters: [
    ->(name:) { where('lower(name) like ?', "%#{name.downcase}%") },
    ->(genre:) { where(genre: genre) },
    ->(sort:) { order(sort.to_sym) },
  ]
end
```

### Functional style
Call Rack::Reducer as a function, maybe right in your controllers, maybe in
a dedicated [query object][query_obj], or really anywhere you like:

```ruby
# app/controllers/artists_controller.rb
class ArtistsController < ApplicationController
  def index
    @artists = Rack::Reducer.call(params, dataset: Artist.all, filters: [
      ->(name:) { where('lower(name) like ?', "%#{name.downcase}%") },
      ->(genre:) { where(genre: genre) },
      ->(sort:) { order(sort.to_sym) },
    ])
    render json: @artists
  end
end
```

The mixin style is stylistically Railsier. The functional style is more
flexible. Both styles are supported, tested, and handle requests identically.

In the examples above:

```ruby
# GET /artists returns all artists, e.g.
[
  { "name": "Blake Mills", "genre": "alternative" },
  { "name": "Björk", "genre": "electronic" },
  { "name": "James Blake", "genre": "electronic" },
  { "name": "Janelle Monae", "genre": "alt-soul" },
  { "name": "SZA", "genre": "alt-soul" }
]

# GET /artists?name=blake returns artists named 'blake',  e.g.
[
  { "name": "Blake Mills", "genre": "alternative" },
  { "name": "James Blake", "genre": "electronic" }
]

# GET /artists?name=blake&genre=electronic returns e.g.
[{ "name": "James Blake", "genre": "electronic" }]
```


Framework-specific Examples
---------------------------
These examples apply Rack::Reducer in different frameworks and ORMs. The
pairings of ORMs and frameworks are arbitrary, just to demonstrate a few
possible stacks.

- [Sinatra/Sequel](#sinatrasequel)
- [Rack Middleware/Ruby Hash](#rack-middlewarehash)
- [Roda](#roda)
- [Hanami](#hanami)
- [Advanced use in Rails and other frameworks](#advanced-use-in-rails-and-other-frameworks)

### Sinatra/Sequel
This example uses [Sinatra][sinatra] to handle requests, and [Sequel][sequel]
as an ORM.

#### Functional-style
```ruby
# sinatra_functional_style.rb
class SinatraFunctionalApp < Sinatra::Base
  DB = Sequel.connect ENV['DATABASE_URL']

  # dataset is a Sequel::Dataset, so filters use Sequel query methods
  QUERY = {
    dataset: DB[:artists],
    filters: [
      ->(genre:) { where(genre: genre) },
      ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
      ->(sort:) { order(sort.to_sym) },
    ]
  }

  get '/artists' do
    @artists = Rack::Reducer.call(params, QUERY)
    @artists.to_a.to_json
  end
end
```

#### Mixin-style
```ruby
# sintra_mixin_style.rb
class SinatraMixinApp < Sinatra::Base
  class Artist < Sequel::Model
    extend Rack::Reducer
    reduces self.dataset, filters: [
      ->(genre:) { where(genre: genre) },
      ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
      ->(sort:) { order(sort.to_sym) },
    ]
  end

  get '/artists' do
    @artists = Artist.reduce(params)
    @artists.to_a.to_json
  end
end
```

### Rack Middleware/Hash
This example runs a raw Rack app with Rack::Reducer mounted as middleware.
It doesn't use an ORM at all -- it just stores data in a ruby hash.

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
  use Rack::Reducer, dataset: ARTISTS, filters: [
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
use Rack::Reducer, key: 'myapp.custom_key', dataset: ARTISTS, filters: [
  #an array of lambdas
]
```

### Roda
This example uses [Roda][roda] to handle requests, and [Sequel][sequel] as an
ORM.

```ruby
# app.rb
require 'roda'
require 'sequel'

class App < Roda
  plugin :json

  DB = Sequel.connect ENV['DATABASE_URL']

  QUERY = {
    dataset: DB[:artists],
    filters: [
      ->(genre:) { where(genre: genre) },
      ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
      ->(sort:) { order(sort.to_sym) },
    ]
  }
  # Note that QUERY[:dataset] is a Sequel::Dataset, so the functions 
  # in QUERY[:filters] use Sequel methods

  route do |r|
    r.get('artists') { Rack::Reducer.call(r.params, QUERY).to_a }
  end
end
```

### Hanami
This example uses [Hanami][hanami] to handle requests, and hanami-model as an
ORM.

```ruby
# apps/web/controllers/artists/index.rb
module Web::Controllers::Artists
  class Index
    include Web::Action

    def call(params)
      @artists = ArtistRepository.new.reduce(params)
      self.body = @artists.to_a.to_json
    end
  end
end

# lib/app_name/repositories/artist_repository.rb
class ArtistRepository < Hanami::Repository
  def reduce(params)
    Rack::Reducer.call(params, dataset: artists.dataset, filters: [
      ->(genre:) { where(genre: genre) },
      ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
      ->(sort:) { order(sort.to_sym) },
    ])
  end
end
```

### Advanced use in Rails and other frameworks
The examples in the [introduction](#use) cover basic Rails use. The examples
below cover more advanced use.

If you're comfortable in a non-Rails stack, you can apply these advanced
techniques there too.

#### Default filters
Most of the time it makes sense to use *required* keyword arguments for each
filter, and skip running the filter altogether when the keyword argments aren't
present.

But you may want to run a filter always, with a sensible default when the params
don't specify a value. Ordering results is a common case.

The code below will order by `params[:sort]` when it exists, and by name
otherwise.

```ruby
# app/controllers/artists_controller.rb
class ArtistsController < ApplicationController
  def index
    @artists = Rack::Reducer.call(params, dataset: Artist.all, filters: [
      ->(genre:) { where(genre: genre) },
      ->(sort: 'name') { order(sort.to_sym) }
    ])
    render json: @artists
  end
end
```

#### Dynamically setting Reducer's initial dataset
Rack::Reducer's mixin style only lets you target one initial dataset for
reduction. If you need different initial datasets in different contexts, use
the functional style:

```ruby
# app/controllers/artists_controller.rb
class ArtistsController < ApplicationController
  def index
    @scope = current_user.admin? ? Artist.all : Artist.signed
    @artists = Rack::Reducer.call(params, dataset: @scope, filters: [
      ->(name:) { by_name(name) },
      ->(genre:) { where(genre: genre) },
      ->(sort:) { order(sort.to_sym) }
    ])
    render json: @artists
  end
end
```

#### Chaining reduce with other ActiveRecord query methods
In the mixin-style, you can chain `Model.reduce` with other ActiveRecord
queries, as long as `reduce` is the first call in the chain:

```ruby
# app/models/artist.rb
class Artist < ApplicationRecord
  extend Rack::Reducer
  reduces self.all, filters: [
    # filters get instance_exec'd against the initial dataset, 
    # in this case `self.all`, so filters can use query methods, scopes, etc
    ->(name:) { by_name(name) },
    ->(genre:) { where(genre: genre) },
    ->(sort:) { order(sort.to_sym) }
  ]

  scope :by_name, lambda { |name|
    where('lower(name) like ?', "%#{name.downcase}%")
  }

  # here's a scope we're not using in our Reducer filters,
  # but will use in our controller
  scope :signed, lambda { where(signed: true) }
end

# app/controllers/artists_controller.rb
class ArtistsController < ApplicationController
  def index
    # you can chain reduce with other ActiveRecord queries,
    # as long as reduce is first in the chain
    @artists = Artist.reduce(params).signed
    render json: @artists
  end
end
```

How Rack::Reducer Works
--------------------------------------
Rack::Reducer takes a dataset, a params hash, and an array of lambda functions.

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

### Security
Rack::Reducer claims to "safely" map URL params to filters, but it accepts an
unfiltered params hash. What gives?

By using keyword arguments in your filter lambdas, you are explicitly naming
the params you'll accept into your filters. Params that aren't keywords never 
get evaluated.

For extra safety, you can typecast the params in your filters. Many ORMs
handle this for you, but as an example:

```ruby
FILTERS = [
  # typecast params[:name] to a string
  ->(name:) { where(name: name.to_s) },
  # typecast params[:updated_before] and params[:updated_after]
  # to times, and set a default for updated_after if it's missing
  lambda |updated_before:, updated_after: 1.month.ago| {
    where(updated_at: updated_after.to_time..updated_before.to_time)
  }
]
```

### Performance
According to `spec/benchmarks.rb`, Rack::Reducer executes about 90% as quickly
as a set of hard-coded conditional filters. It is unlikely to be a
bottleneck in your application.

Alternatives
-------------------
If you're working in Rails, Plataformatec's excellent [HasScope][has_scope] has
been solving this problem since 2009. I prefer keeping my query logic all in one
place, though, instead of spreading it across my controllers and models.

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
Please include tests, following the style of the specs in `spec/*_spec.rb`.

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
[roda]: https://github.com/jeremyevans/roda
[reduce]: http://ruby-doc.org/core-2.5.0/Enumerable.html#method-i-reduce
[keywords]: https://robots.thoughtbot.com/ruby-2-keyword-arguments
[query_obj]: https://robots.thoughtbot.com/using-yieldself-for-composable-activerecord-relations
[periscope]: https://github.com/laserlemon/periscope
[hanami]: http://hanamirb.org
