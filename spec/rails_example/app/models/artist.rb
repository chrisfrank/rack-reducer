class Artist < ApplicationRecord
  extend Rack::Reducer
  reduces all, via: [
    # filters can call class methods...
    ->(genre:) { search_genre(genre) },
    # or scopes...
    ->(name:) { by_name(name) },
    # or inline ActiveRecord queries
    lambda { |released_before:|
      where('last_release < ?', released_before)
    },
  ]

  scope :by_name, lambda { |name|
    where('lower(name) like ?', "%#{name.downcase}%")
  }

  def self.search_genre(genre)
    where('lower(genre) like ?', "%#{genre.downcase}%")
  end
end
