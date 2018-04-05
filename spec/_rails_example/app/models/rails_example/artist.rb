module RailsExample
  class Artist < ApplicationRecord
    scope :by_name, lambda { |name|
      where('lower(name) like ?', "%#{name.downcase}%")
    }
    def self.search_genre(genre)
      where('lower(genre) like ?', "%#{genre.downcase}%")
    end

    extend Rack::Reducer
    reduces all, filters: [
      # filters can call class methods...
      ->(genre:) { search_genre(genre) },
      # or scopes...
      ->(name:) { by_name(name) },
      # or inline ActiveRecord queries
      ->(order:) { order(order.to_sym) },
      ->(releases: ) { where(release_count: releases.to_i) },
    ]
  end
end
