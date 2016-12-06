require 'sinatra'
require 'sinatra'
require 'sinatra'
require 'sinatra'
require 'sinatra'
require 'sinatra'
require 'sinatra'
require 'sinatra'

configure :development do
	require 'dotenv'
	Dotenv.load
end

Dir['./models/*.rb'].each {|file| require file}
Dir['./helpers/*.rb'].each {|file| require file}

enable :sessions

helpers Sinatra::DateTimeHelper
helpers Sinatra::DateTimeHelper
helpers Sinatra::DateTimeHelper

get '/' do
	haml :index
end

get '/oauth' do
	code = params [:code]

	slack_oauth_request = "https://slack.com/api/oauth.access"

	if code
		
	end

end