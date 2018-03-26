require 'bundler/setup'
require 'hanami/setup'
require 'hanami/model'
require_relative '../lib/hanami_example'
require_relative '../apps/web/application'

Hanami.configure do
  mount Web::Application, at: '/'

  model do
    ##
    # Database adapter
    #
    # Available options:
    #
    #  * SQL adapter
    #    adapter :sql, 'sqlite://db/hanami_example_development.sqlite3'
    #    adapter :sql, 'postgresql://localhost/hanami_example_development'
    #    adapter :sql, 'mysql://localhost/hanami_example_development'
    #
    adapter :sql, "sqlite://#{__dir__}/../../fixtures.sqlite"

    ##
    # Migrations
    #
    migrations 'db/migrations'
    schema     'db/schema.sql'
  end
end
