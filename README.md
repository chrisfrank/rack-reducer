Rack::Reducer
=============
Safely map URL params to database filters, in any Rack app.
If your users need to filter data by making HTTP requests, this gem can help.

Rack::Reducer solves the same problem has [Platformatec][1]’s excellent 
[HasScope][2], but it works in any Rack app, with any ORM, and has a simpler,
more functional API. It also works with no ORM at all.

If you're working in Rails, see the [Rails](#rails) section below for more
on which gem might best fit your needs.

Install
-------
Add `rack-reducer` to your Gemfile:

```ruby
gem 'rack-reducer', require: 'rack/reducer'
```

If your app doesn't `Bundler.require` your whole Gemfile, be sure to

```ruby
require 'rack/reducer'
```
when you need it.

Use
---
Rack::Reducer maps incoming URL params to an array of filter functions you
define. Suppose you have some incoming requests like these...

`GET /artists`  
`GET /artists?name=SZA`  
`GET /artists?name=blake&genre=electronic`

You want to filter your `artists` table by name and/or genre when those
params are present, and return all artists otherwise.

#### Mixin-style
You can use Rack::Reducer as a mixin on your models:

```ruby
# app/models/artist.rb

class Artist < RailsLike::Model
  extend Rack::Reducer
  reduces self.all, filters: [
    ->(:name) { where('lower(name) like ?', "%#{name.downcase}%") },
    ->(:genre) { where(genre: genre) }
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

# GET /artists?name=blake&genre=electronic
# returns e.g. [{ "name": "James Blake", "genre": "electronic" }]
```

#### Functional style
Alternatively, you can call Rack::Reducer as a function:

```ruby
# a_sinatra_app.rb

class App < Sinatra::Base
  FILTERS = [
    ->(:name) { where('lower(name) like ?', name.downcase) },
    ->(:genre) { where(genre: genre) }
  ]

  get '/artists' do
    @artists = Rack::Reducer.call(params, dataset: Artist.all, filters: FILTERS)
    @artists.to_json
  end
end

# GET /artists?name=blake&genre=alternative
# returns e.g. [{ "name": "Blake Mills", "genre": "alternative" }]
```

The mixin style enforces more conventions, and is a Railsier way of writing.
The functional style is more powerful. Both styles are tested and supported.

Framework-specific Examples
---------------------------
These examples apply Rack::Reducer in different frameworks, with a different
ORM in each example. The pairing of Framework/ORM is arbitrary.
[Sinatra][sinatra]/[Sequel][sequel] could work just as well with ActiveRecord,
Middleware/Hash could use Mongoid, and so on.

- [Sinatra](#sinatra-sequelmodel)
- [Roda](#roda-sequeldataset)
- [Rack Middleware](#rack-middlewarehash)
- [Rails](#rails)

### Sinatra/Sequel::Model
TODO

### Roda w/Sequel::Dataset
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
