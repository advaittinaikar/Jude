source 'https://rubygems.org'

gem 'sinatra'
gem 'json'
gem 'shotgun'
gem "rake"
gem 'activerecord'
gem 'sinatra-activerecord' # excellent gem that ports ActiveRecord for Sinatra
gem 'activesupport'
gem 'kronic'
gem 'google-api-client', '~> 0.9'

# gem 'google/apis/calendar_v3'
# gem 'googleauth'
# gem 'googleauth/stores/file_token_store'

gem 'haml'
gem 'slack-ruby-client'
gem 'httparty'


# to avoid installing postgres use 
# bundle install --without production

group :development, :test do
  gem 'sqlite3'
  gem 'dotenv'
end

group :production do
  gem 'pg'
end
