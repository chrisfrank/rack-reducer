require 'spec_helper'
ENV['RACK_ENV'] = ENV['RAILS_ENV'] = 'test'
require_relative 'rails_example/config/environment'

describe Rails.application do
  it_behaves_like Rack::Reducer
end
