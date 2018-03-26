require 'spec_helper'
require 'json'

# mount Rack::Reducer as middleware, let it filter data into env['rack.reduction'],
# and respond with env['rack.reduction'].to_json
module MiddlewareTest
  DEFAULTS = {
    dataset: DB[:artists].all,
    filters: [
      ->(genre:) { select { |item| item[:genre].match(/#{genre}/i) } },
      ->(name:) { select { |item| item[:name].match(/#{name}/i) } },
      ->(order:) { sort_by { |item| item[order.to_sym] } }
    ]
  }

  def self.app(options = {}, key = options[:key] || 'rack.reduction')
    Rack::Builder.new do
      use Rack::Reducer, DEFAULTS.merge(options)
      run ->(env) { [200, {}, [env[key].to_json]] }
    end
  end
end

describe MiddlewareTest.app do
  it_behaves_like Rack::Reducer
end

describe MiddlewareTest.app(key: 'some.custom.key') do
  it_behaves_like Rack::Reducer
end
