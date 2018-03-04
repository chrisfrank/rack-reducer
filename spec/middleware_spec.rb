require 'spec_helper'
require_relative 'fixtures'
require 'json'

# mount Rack::Reducer as middleware, let it filter data into env['rack.reduction'],
# and respond with env['rack.reduction'].to_json
module MiddlewareTest
  def self.app
    Rack::Builder.new do
      use Rack::Reducer, dataset: ARTISTS, filters: [
        ->(genre:) { select { |item| item[:genre].match(/#{genre}/i) } },
        ->(name:) { select { |item| item[:name].match(/#{name}/i) } },
        ->(order:) { sort_by { |item| item[order.to_sym] } }
      ]
      run ->(env) { [200, {}, [env['rack.reduction'].to_json]] }
    end
  end
end

describe MiddlewareTest.app do
  it_behaves_like Rack::Reducer
end
