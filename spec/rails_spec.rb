require 'spec_helper'
require_relative '_rails_example/config/environment'

describe Rails.application do
  it_behaves_like Rack::Reducer
end
