source 'https://rubygems.org'

# ruby '2.2.6'

gem 'sinatra'
gem 'launchy'
gem 'json'
gem 'shotgun'
gem "rake"
gem 'activerecord'
gem 'sinatra-activerecord' # excellent gem that ports ActiveRecord for Sinatra
gem 'activesupport'
gem 'kronic'
gem 'google-api-client'
gem 'googleauth'

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
