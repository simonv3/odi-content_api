source 'https://rubygems.org'
source 'https://BnrJb6FZyzspBboNJzYZ@gem.fury.io/govuk/'

gem 'unicorn', '4.6.2'
gem 'rake', '0.9.2.2'
gem 'sinatra', '1.3.2'
gem 'rabl', '0.6.14'
gem 'statsd-ruby', '1.0.0'
gem 'omniauth-gds', '0.0.3' #rubygems doesn't seem to pull this in transitively

if ENV['CONTENT_MODELS_DEV']
  gem 'govuk_content_models', path: '../govuk_content_models'
else
  gem 'govuk_content_models', '5.9.0'
end

# Pinning mongo to prevent bundler downgrading it in order to upgrade bson
# (as seen in 680d3e9ab7)
gem 'mongo', '>= 1.6.2'

gem 'gds-sso', '3.0.1'
if ENV['API_DEV']
  gem 'gds-api-adapters', :path => '../gds-api-adapters'
else
  gem 'gds-api-adapters', '7.2.0'
end

gem 'govspeak', '1.0.1'
gem 'plek', '1.3.1'
gem 'router-client', '3.1.0', :require => false
gem 'yajl-ruby'
gem 'aws-ses'
gem 'kaminari', '0.14.1'
gem 'link_header', '0.0.5'
gem 'rack-cache', '1.2'
gem 'redis-rack-cache', '1.2.1'

group :test do
  gem 'database_cleaner', '0.7.2'
  gem 'factory_girl', '3.6.1'
  gem 'mocha', '0.12.4', require: false
  gem 'simplecov', '0.6.4'
  gem 'simplecov-rcov', '0.2.3'
  gem 'minitest', '3.4.0'
  gem 'ci_reporter', '1.7.0'
  gem 'webmock', '~> 1.8', require: false
  gem 'timecop', '0.5.9.2'
end

group :development do
  # (Intelligent) reloading server in development
  gem "mr-sparkle", "0.2.0"
end
