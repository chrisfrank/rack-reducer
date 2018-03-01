class Artist < ApplicationRecord
  scope :by_name, lambda { |name|
    where('lower(name) like ?', "%#{name.downcase}%")
  }

  def self.search_genre(genre)
    where('lower(genre) like ?', "%#{genre.downcase}%")
  end

  def self.reduce(params)
    Rack::Reducer.call(data: self.all, params: params, filters: FILTERS)
  end

  FILTERS = [
    # filters can call class methods...
    ->(genre:) { self.search_genre(genre) },
    # or scopes...
    ->(name:) { self.by_name(name) },
    # or inline ActiveRecord queries
    lambda { |released_before:|
      where('last_release < ?', released_before)
    },
  ]
end
