require "sinatra"
require 'sinatra/activerecord'
require 'rake'
require 'active_support/all'
require "active_support/core_ext"

require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

require 'kronic'

require 'haml'
require 'json'
require 'slack-ruby-client'
require 'httparty'

# ----------------------------------------------------------------------

# Load environment variables using Dotenv. If a .env file exists, it will
# set environment variables from that file (useful for dev environments)
configure :development do
  require 'dotenv'
  Dotenv.load
end

#require any models 

Dir["./models/*.rb"].each {|file| require file }

Dir["./helpers/*.rb"].each {|file| require file }

#require helper files
helpers Sinatra::CommandsHelper
helpers Sinatra::CalendarHelper
helpers Sinatra::DatabaseHelper
helpers Sinatra::SlackInteractionsHelper


#global variables to be used in app
@@jude_link = "http://agile-stream-68169.herokuapp.com/"
$assignment_record = ""
$assignment_object = {}
$course_object = {}

# enable sessions for this project
enable :sessions

# OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
# CREDENTIALS_PATH = File.join(Dir.home, '.credentials', "calendar-ruby-quickstart.yaml")
# CALENDAR_SCOPE = ['https://www.googleapis.com/auth/calendar']

# configure do
#   # log_file = File.open('calendar.log', 'a+')
#   # log_file.sync = true
#   # logger = Logger.new(log_file)
#   # logger.level = Logger::DEBUG

#   client = Google::APIClient.new(
#     :application_name => 'Jude Bot')
  
#   file_storage = Google::APIClient::FileStorage.new(CREDENTIAL_STORE_FILE)
#   if file_storage.authorization.nil?
#     client_secrets = Google::APIClient::ClientSecrets.load
#     client.authorization = client_secrets.to_authorization
#     client.authorization.scope = 'https://www.googleapis.com/auth/calendar'
#   else
#     client.authorization = file_storage.authorization
#   end

#   # Since we're saving the API definition to the settings, we're only retrieving
#   # it once (on server start) and saving it between requests.
#   # If this is still an issue, you could serialize the object and load it on
#   # subsequent runs.
#   calendar = client.discovered_api('calendar', 'v3')

#   # set :logger, logger
#   set :api_client, client
#   set :calendar, calendar
# end

# # before do
# #   # Ensure user has authorized the app
# #   unless user_credentials.access_token || request.path_info =~ /\A\/oauth2/
# #     redirect to('/oauth2authorize')
# #   end
# # end

# after do
#   # Serialize the access/refresh token to the session and credential store.
#   session[:access_token] = user_credentials.access_token
#   session[:refresh_token] = user_credentials.refresh_token
#   session[:expires_in] = user_credentials.expires_in
#   session[:issued_at] = user_credentials.issued_at

#   file_storage = Google::APIClient::FileStorage.new(CREDENTIAL_STORE_FILE)
#   file_storage.write_credentials(user_credentials)
# end

# get '/oauth2authorize' do
#   # Request authorization
#   redirect user_credentials.authorization_uri.to_s, 303
# end

# get '/oauthcallback' do
#   # Exchange token
#   user_credentials.code = params[:code] if params[:code]
#   user_credentials.fetch_access_token!
#   redirect to('/')
# end

# # # Initialize the calendar API
# calendar_service = Google::Apis::CalendarV3::CalendarService.new
# calendar_service.client_options.application_name = 'Google Calendar API Ruby Quickstart'
# calendar_service.authorization = authorize_calendar

# ----------------------------------------------------------------------
#     ROUTES, END POINTS AND ACTIONS
# ----------------------------------------------------------------------

#
get "/" do
  haml :index
end

get "/privacy" do
  "Privacy Statement"
end

get "/about" do
  "About this app"
end

# ----------------------------------------------------------------------
#     OAUTH
# ----------------------------------------------------------------------

# This will handle the OAuth stuff for adding our app to Slack
# https://99designs.com/tech-blog/blog/2015/08/26/add-to-slack-button/
# check it out here. 

get "/oauth" do
  
  code = params[ :code ]
  
  puts "All good till here"

  slack_oauth_request = "https://slack.com/api/oauth.access"

  puts "All good till here too!"
  
  if code 
    response = HTTParty.post slack_oauth_request, body: {client_id: ENV['SLACK_CLIENT_ID'], client_secret: ENV['SLACK_CLIENT_SECRET'], code: code}
    
    puts response.to_s
    
    # We can extract lots of information from this web hook... 
    
    access_token = response["access_token"]
    team_name = response["team_name"]
    team_id = response["team_id"]
    user_id = response["user_id"]
        
    incoming_channel = response['incoming_webhook']['channel']
    incoming_channel_id = response['incoming_webhook']['channel_id']
    incoming_config_url = response['incoming_webhook']['configuration_url']
    incoming_url = response['incoming_webhook']['url']
    
    bot_user_id = response['bot']['bot_user_id']
    bot_access_token = response['bot']['bot_access_token']
    
    # wouldn't it be useful if we could store this? 
    # we can... 
    
    team = Team.find_or_create_by( team_id: team_id, user_id: user_id )
    team.access_token = access_token
    team.team_name = team_name
    team.raw_json = response.to_s
    team.incoming_channel = incoming_channel
    team.incoming_webhook = incoming_url
    team.bot_token = bot_access_token
    team.bot_user_id = bot_user_id
    team.save
    
    # finally respond... 
    "Jude has been successfully installed. Go check her out!"

    unless sessions[:access_token].nil?
     auth_calendar
    end
    
  else
    401
  end
  
end

#ENDPOINT: The redirect_url entered in Google Console. 
#Google Oauth redirects to this endpoint once user has authorised request.
get '/oauthcallback' do

  client = Signet::OAuth2::Client.new({

      client_id: ENV['CALENDAR_CLIENT_ID'],
      client_secret: ENV['CALENDAR_CLIENT_SECRET'],
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      redirect_uri: "https://agile-stream-68169.herokuapp.com/oauthcallback",
      code: params[:code]

    })

  response = client.fetch_access_token!

  session[:access_token] = response['access_token']

  # finally respond... 
  "Jude has been successfully installed. Your Calendar has been successfully synced with Jude.\nPlease login to your Slack team to meet Jude!"

end

# ----------------------------------------------------------------------
#     OUTGOING WEBHOOK FROM SLACK
# ----------------------------------------------------------------------

# ANY EVENT: Endpoint for an event subscription

post "/events" do
  request.body.rewind
  raw_body = request.body.read
  puts "Raw: " + raw_body.to_s
  
  json_request = JSON.parse( raw_body )

  # check for a URL Verification request.
  if json_request['type'] == 'url_verification'
      content_type :json
      return {challenge: json_request['challenge']}.to_json
  end

  if json_request['token'] != ENV['SLACK_VERIFICATION_TOKEN']
      halt 403, 'Incorrect slack token'
  end

  respond_to_slack_event json_request
  
  # always respond with a 200
  # event otherwise it will retry...
  200
  
end

# ANY EVENT: Endpoint for an interactive message interaction. Control center for all button interactions.

post '/interactive-buttons' do

  content_type :json

  request.body.rewind
  raw_body = request.body.read

  # puts "Params: " + params.to_s
  
  json_request = JSON.parse( params["payload"] )
  # puts "JSON = " + json_request.to_s
  puts "checking token"

  if json_request['token'] != ENV['SLACK_VERIFICATION_TOKEN']
      halt 403, 'Incorrect slack token'
  end
  
  puts "token valid"

  call_back = json_request['callback_id']
  action_name = json_request['actions'].first["name"]
  action_text = json_request['actions'].first["text"]
  action_value = json_request['actions'].first["value"]
  channel = json_request['channel']['id']
  team_id = json_request['team']['id']
  time_stamp = json_request['message_ts']
  
  # puts "Action: " + call_back.to_s
  # puts "Call Back: " + action_name.to_s
  # puts "team_id : " + team_id.to_s
  # puts "channel : " + channel.to_s
  
  team = Team.find_by( team_id: team_id )
  puts team

  if team.nil?
    client.chat_postMessage(channel: channel, text:"You don't have Jude installed. Click the below link to install: http://agile-stream-68169.herokuapp.com/", unfurl_links: true)
    return
  end
  
  puts "team found!"
  
  client = team.get_client
  
  if call_back == "to-do"
      message = "Great! "
    
      if action_name == "add"

        $assignment_record=""

        message += "Let's add an assignment!"
      
        client.chat_postMessage(channel: channel, text: message, attachments: interactive_assignment_course, as_user: true)
        {  text: "You selected 'add an assignment'" , replace_original: true }.to_json

      elsif action_name == "show today"

        client.chat_postMessage(channel: channel, text: show_next_events, as_user: true)
        {  text: "You selected 'show today'" , replace_original: true }.to_json

      elsif action_name == "show next"
        # calendar_upcoming_events $service
        client.chat_postMessage(channel: channel, text: show_next_events, as_user: true) 
        {  text: "You selected 'show next'" , replace_original: true }.to_json

      else
        # client.chat_postMessage(channel: channel, text: replace_message, as_user: true)
        200
      end

  elsif call_back == "course_assignment"
    if action_name == "add course"
      client.chat_postMessage(channel: channel, text: "Enter Course Name starting with ~course name: ~", as_user: true)
      {  text: "You selected 'add a course'" , replace_original: true }.to_json
    else
      message = "You're adding an assignment for #{action_name}!"
      
      $assignment_record = "For #{action_name}: "
      $assignment_object[:course_name] = action_text
      client.chat_postMessage(channel: channel, text: message, attachments: [{"text": "Please type your assignment details in <= 140 chars", "callback_id": "assignment_text"}].to_json, as_user: true)
    
      {  text: "You selected 'add an assignment'" , replace_original: true }.to_json
    end  
  
  else
    200
    # do nothing... 
  end

end

# CALL AS FOLLOWS
# curl -X POST http://127.0.0.1:9393/test_event -F token=9GCx7G3WrHix7EJsP818YOVB -F team_id=T2QJ6HA0Z -F event_type=message -F event_user=U2QHR0F7W -F event_channel=D37HZB04D -F event_ts=1480296595.000007 -F event_text='g ddf;gkl;d fkg;ldfkg df' 

post '/calendar_events' do

end

#     ERRORS

error 401 do
  "Invalid response or malformed request"
end

#   METHODS

private

#METHOD: Responds to a slack event that is passed to the "/events" endpoint.
# => Returns method event_to_action.

def respond_to_slack_event json
  
  # find the team
  team_id = json['team_id']
  api_app_id = json['api_app_id']
  event = json['event']
  event_type = event['type']
  event_user = event['user']
  event_text = event['text']
  event_channel = event['channel']
  event_ts = event['ts']
  
  team = Team.find_by( team_id: team_id )
  
  # didn't find a match... this is junk! 
  return if team.nil?
  
  # see if the event user is the bot user 
  # if so we shoud ignore the event
  return if team.bot_user_id == event_user
  
  event = Event.create( team_id: team_id, type_name: event_type, user_id: event_user, text: event_text, channel: event_channel , timestamp: Time.at(event_ts.to_f) )
  event.team = team
  event.save
  
  client = team.get_client
  
  event_to_action client, event
  
end

