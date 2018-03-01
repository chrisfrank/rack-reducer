Rack::Reducer
=============
Filter your app's data via request params, safely and methodically.

Rack::Reducer solves the same problem has Platformatec’s
[HasScope](https://github.com/plataformatec/has_scope), but it works in any Rack
app, with any ORM, and has a simpler, more functional API. Where `has_scope`
requires you to spread filters across your Controllers and Models, Rack::Reducer
lets you put code wherever you like, and encourages you to keep it all in one
place.

Install
-------
1. Add `gem rack-reducer` to your Gemfile.
2. `bundle install`
3. `require rack/reducer` in your app.

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

    # app/models/artist.rb
    class Artist < RailsLike::Model
      extend Rack::Reducer
      reduces self.all, filters: [
        ->(:name) { where('lower(name) like ?', "%#{name.downcase}%") },
        ->(:genre) { where(genre: genre) }
      ]
    end

    # app/controllers/artists_controller.rb
    class ArtistsController < ApplicatonController
      def index
        @artists = Artist.reduce(params)
        @artists.to_json
      end
    end

#### Functional style
You can also call Rack::Reducer as a function:

    # cool_sinatra_app.rb
    class App < Sinatra::Base
      FILTERS = [
        ->(:name) { where('lower(name) like ?', name.downcase) },
        ->(:genre) { where(genre: genre) }
      ]

      get '/artists' do
        @artists = Rack::Reducer.call(
          params,
          dataset: Artist.all,
          filters: FILTERS
        )
        @artists.to_json # [{ name: 'James Blake', genre: 'electronic' }]
      end
    end

The mixin style enforces more conventions, and is a Railsier way of writing.
The functional style is more powerful. Both styles are tested and supported.

Framework-specific Examples
---------------------------
- [Sinatra](#sinatra)
- [Roda](#roda)
- [Rack Middleware](#rack-middleware)
- [Rails](#rails)

### Sinatra

### Roda

### Rack Middleware

### Rails

How Rack::Reducer Works
-----------------------
