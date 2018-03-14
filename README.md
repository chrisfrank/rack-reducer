Rack::Reducer
==========================================
[![Build Status](https://travis-ci.org/chrisfrank/rack-reducer.svg?branch=master)](https://travis-ci.org/chrisfrank/rack-reducer)
[![Maintainability](https://api.codeclimate.com/v1/badges/675e7a654c7e11c24b9f/maintainability)](https://codeclimate.com/github/chrisfrank/rack-reducer/maintainability)

Safely map URL params to functions that filter data, in any Rack app.

Rack::Reducer handles param sanitizing, filter chaining, and conditional
filtering on your behalf. It can make your controller logic as simple as 
`@artists = Artist.reduce(params)`.

Your filter functions can ultimately be Rails scopes, inline lambdas, or methods
on a [query object][query_obj] — Rack::Reducer doesn’t care. It works in any 
Rack-compatible app, with any ORM, and has no dependencies beyond Rack itself.

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
`GET /artists?name=janelle+monae`  
`GET /artists?name=blake&genre=electronic`

You want to filter your `artists` table by name and/or genre when those
params are present, or return all artists otherwise.

Even with just a few optional filters, running them conditonally via `if` 
statements gets messy.

### A Mess

```ruby
# app/controllers/artists_controller.rb
class ArtistsController < ApplicationController
  def index
    @artists = Artist.all
    @artists = @artists.where('lower(name) like ?', "%#{name.downcase}%") if params[:name]
    @artists = @artists.where(genre: params[:genre]) if params[:genre]
    @artists = @artists.order(params[:order].to_sym) if params[:order]
    # ...
    # ...
    # pages later...
    @artists.all.to_json
  end
```

Rack::Reducer helps you clean this mess up, in your choice of two styles.

### Cleaned up by extending Rack::Reducer
Call `Model.reduce(params)` in your controllers...

```ruby
# app/controllers/artists_controller.rb
class ArtistsController < ApplicationController
  def index
    @artists = Artist.reduce(params)
    @artists.all.to_json
  end
end
```

... and `extend Rack::Reducer` in your models:

```ruby
# app/models/artist.rb
class Artist < ActiveRecord::Base
  extend Rack::Reducer # makes `self.reduce` available at class level

  # Configure by calling
  # `reduces(some_initial_scope, filters: [an, array, of, lambdas])`
  #
  # Filters can use any methods your initial dataset understands.
  # Here it's an ActiveRecord query, so filters use AR query methods.
  reduces self.all, filters: [
    ->(name:) { where('lower(name) like ?', "%#{name.downcase}%") },
    ->(genre:) { where(genre: genre) },
    ->(order:) { order(order.to_sym) },
  ]
end
```

### Cleaned up by calling Rack::Reducer as a function
If you prefer composition to inheritance, you can call Rack::Reducer as a
function instead of extending it. The functional style can help keep your 
filtering logic in one file, and let you use Rack::Reducer without polluting
your model's methods.

```ruby
# app/controllers/artists_controller.rb
class ArtistsController < ApplicationController
  def index
    @artists = Rack::Reducer.call(params, dataset: Artist.all, filters: [
      ->(name:) { where('lower(name) like ?', "%#{name.downcase}%") },
      ->(genre:) { where(genre: genre) },
      ->(order:) { order(order.to_sym) },
    ])
    @artists.all.to_json
  end
end
```

The mixin style requires less boilerplate, and is stylistically Railsier.
The functional style is more flexible. Both styles are supported, tested, and
handle requests identically. In the examples above:

```ruby
# GET /artists returns all artists, e.g.
[
  { "name": "Blake Mills", "genre": "alternative" },
  { "name": "Björk", "genre": "electronic" },
  { "name": "James Blake", "genre": "electronic" },
  { "name": "Janelle Monae", "genre": "alt-soul" },
  { "name": "SZA", "genre": "alt-soul" }
]

# GET /artists?name=blake returns e.g.
[
  { "name": "Blake Mills", "genre": "alternative" },
  { "name": "James Blake", "genre": "electronic" }
]

# GET /artists?name=blake&genre=electronic returns e.g. 
[{ "name": "James Blake", "genre": "electronic" }]
```


Framework-specific Examples
---------------------------
These examples apply Rack::Reducer in different frameworks, with a different
ORM each time. The pairings of ORMs and frameworks are arbitrary, just to
demonstrate a few possible stacks.

- [Sinatra/Sequel](#sinatrasequel)
- [Rack Middleware/Ruby Hash](#rack-middlewarehash)
- [Rails](#railsadvanced)

### Sinatra/Sequel
This example uses [Sinatra][sinatra] to handle requests, and [Sequel][sequel]
as an ORM.

#### Mixin-style
```ruby
# sintra_mixin_style.rb
class SinatraMixinApp < Sinatra::Base
  class Artist < Sequel::Model
    extend Rack::Reducer
    reduces self.dataset, filters: [
      ->(genre:) { where(genre: genre) },
      ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
      ->(order:) { order(order.to_sym) },
    ]
  end
  
  get '/artists' do
    @artists = Artist.reduce(params)
    @artists.all.to_json
  end
end
```

#### Functional style
```ruby
# sinatra_functional_style.rb
class SinatraFunctionalApp < Sinatra::Base
  DB = Sequel.connect ENV['DATABASE_URL']
  
  get '/artists' do
    # dataset is a Sequel::Dataset, so filters use Sequel query methods
    @artists = Rack::Reducer.call(params, dataset: DB[:artists], filters: [
      ->(genre:) { where(genre: genre) },
      ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
      ->(order:) { order(order.to_sym) },
    ])
    @artists.all.to_json
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
    ->(order:) { sort_by { |item| item[order.to_sym] } },
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

### Rails/Advanced
The examples in the [introduction](#use) cover basic Rails use. The examples
below cover more advanced use.

If you're comfortable in a non-Rails stack, you can apply these advanced
techniques there too. I wholeheartedly endorse [Roda][roda], and use
Rack::Reducer with Roda/Sequel in production.

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
    ->(order:) { order(order.to_sym) }
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
    @artists.to_json
  end
end
```


#### Dynamically setting Reducer's initial dataset
Rack::Reducer's mixin style only lets you target one dataset for reduction.
If you need different initial data in different contexts, and don't want to
determine that data via filters, you can use the functional style:

```ruby
# app/controllers/artists_controller.rb
class ArtistsController < ApplicationController
  def index
    @scope = current_user.admin? ? Artist.all : Artist.signed
    @artists = Rack::Reducer.call(params, dataset: @scope, filters: [
      ->(name:) { by_name(name) },
      ->(genre:) { where(genre: genre) },
      ->(order:) { order(order.to_sym) }
    ])
    @artists.to_json
  end
end
```

#### Default filters
Most of the time it makes sense to use *required* keyword arguments for each
filter, and skip running the filter altogether when the keyword argments aren't
present.

But you may want to run a filter always, with a sensible default when the params
don't specify a value. Ordering results is a common case.

The code below will order by `params[:order]` when it exists, and by name
otherwise.

```ruby
# app/controllers/artists_controller.rb
class ArtistsController < ApplicationController
  def index
    @artists = Rack::Reducer.call(params, dataset: Artist.all, filters: [
      ->(genre:) { where(genre: genre) },
      ->(order: 'name') { order(order.to_sym) }
    ])
    @artists.to_json
  end
end
```


How Rack::Reducer Works
--------------------------------------
Rack::Reducer takes a dataset, a params hash, and an array of lambda functions.

To return filtered data, it calls [reduce][reduce] on your array of lambdas,
with the reduction's initial value set to `dataset`.

Each reduction looks for keys in the `params` hash that match the
current lambda's [keyword arguments][keywords]. If the keys exist, it
`instance_exec`s the lambda against the dataset, passing just those keys as
arguments, and finally passes the filtered dataset on to the next lambda.

Lambdas that don't find all their required keyword arguments in `params` don't
execute at all, and just pass the unaltered dataset down the chain.

The reason Reducer works with any ORM is that *you* supply the dataset and
filter functions. Reducer doesn't need to know anything about ActiveRecord,
Mongoid, etc -- it just `instance_exec`s your own code against your own dataset.

### Security
Rack::Reducer claims to "safely" map URL params to filters, but it accepts an
unfiltered params hash. What gives?

By using keyword arguments in your filter lambdas, you are explicitly naming
the params you'll accept into your filters. Params that aren't keywords never 
get evaluated.

For even more security, you can typecast the params in your filters. Most ORMs
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
as a set of hard-coded conditional filters. It is extremly unlikely to be a
bottleneck in your application.

### Alternatives
If you're working in Rails, Platformatec's excellent [HasScope][has_scope] has
been solving this problem since 2013. I prefer keeping my query logic all in one
place, though, instead of spreading it across my controllers and models.

[Periscope][periscope], by laserlemon, seems like another good Rails option, and
though it's Rails only, it supports more than just ActiveRecord. I have not used
periscope in production.

For Sinatra, Simon Courtois has a [Sinatra port of has_scope][sin_has_scope].
It depends on ActiveRecord.

Contributing
-------------------------------
### Bugs
Open [an issue](https://github.com/chrisfrank/rack-reducer/issues) on Github.

### Pull Requests
Please include tests, following the style of the specs in `spec/*_spec.rb`.



[has_scope]: https://github.com/plataformatec/has_scope
[sin_has_scope]: https://github.com/simonc/sinatra-has_scope
[sinatra]: https://github.com/sinatra/sinatra
[sequel]: https://github.com/jeremyevans/sequel
[roda]: https://github.com/jeremyevans/roda
[reduce]: http://ruby-doc.org/core-2.5.0/Enumerable.html#method-i-reduce
[keywords]: https://robots.thoughtbot.com/ruby-2-keyword-arguments
[query_obj]: https://medium.flatstack.com/query-object-in-ruby-on-rails-56ea434365f0
[periscope]: https://github.com/laserlemon/periscope
