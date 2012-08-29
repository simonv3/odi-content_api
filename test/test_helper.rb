ENV['RACK_ENV'] = 'test'

require "bundler"
Bundler.require(:default, ENV['RACK_ENV'])

require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end

require_relative '../govuk_content_api'
require 'test/unit'
require 'rack/test'
require 'database_cleaner'
require 'mocha'
require 'factory_girl'
require 'govuk_content_models/test_helpers/factories'

DatabaseCleaner.strategy = :truncation
# initial clean
DatabaseCleaner.clean

class GovUkContentApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

end