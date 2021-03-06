source 'https://rubygems.org'
source 'https://BnrJb6FZyzspBboNJzYZ@gem.fury.io/govuk/'

#ruby=ruby-1.9.3
#ruby-gemset=quirkafleeg-content_api

gem 'thin'
gem 'foreman', '< 0.65.0'
gem 'rake', '0.9.2.2'
gem 'rack-protection', "< 1.5.1" # pinned due to slash-encoding change
gem 'sinatra', '1.3.2'
gem 'statsd-ruby', '1.0.0'
gem 'dotenv'

gem 'govuk_content_models', '6.1.0'

if ENV['CONTENT_MODELS_DEV']
  gem "odi_content_models", path: '../odi_content_models'
else
  gem "odi_content_models", github: 'theodi/odi_content_models'
end

# Pinning mongo to prevent bundler downgrading it in order to upgrade bson
# (as seen in 680d3e9ab7)
gem 'mongo', '>= 1.7.1'

gem 'gds-sso', '9.2.0'

gem 'gds-api-adapters', :github => 'theodi/gds-api-adapters'

if ENV['ODIDOWN_DEV']
  gem 'odidown', path: '../odidown'
else
  gem 'odidown', github: 'theodi/odidown'
end

gem 'plek', '1.4.0'
gem 'router-client', '3.1.0', :require => false
gem 'yajl-ruby'
gem 'aws-ses', '0.5.0'
gem 'kaminari', '0.14.1'
gem 'link_header', '0.0.5'
gem 'airbrake'

group :test do
  gem 'database_cleaner', '0.7.2'
  gem 'factory_girl', '3.6.1'
  gem 'mocha', '0.12.4', require: false
  gem 'simplecov', '0.6.4'
  gem 'simplecov-rcov', '0.2.3'
  gem 'minitest', '3.4.0'
  gem 'turn', require: false
  gem 'ci_reporter', '1.7.0'
  gem 'webmock', '~> 1.8', require: false
  gem 'timecop', '0.5.9.2'
  gem 'pry'
end

group :development do
  gem "shotgun"
end
