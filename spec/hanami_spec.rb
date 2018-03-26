require 'spec_helper'
require_relative '_hanami_example/config/boot'

describe Hanami.app do
  it_behaves_like Rack::Reducer
end
