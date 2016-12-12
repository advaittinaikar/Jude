require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'googleauth/web_user_authorizer'
require 'googleauth/stores/redis_token_store'
require 'redis'
require 'launchy'

require "sinatra"
require 'sinatra/activerecord'
require 'rake'
require 'active_support/all'
require "active_support/core_ext"


require 'kronic'
require 'fileutils'

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

helpers Sinatra::CommandsHelper

@@jude_link = "http://agile-stream-68169.herokuapp.com/"
$assignment_record = ""
$assignment_object = {}
# enable sessions for this project
enable :sessions

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials', "calendar-ruby-quickstart.yaml")
CALENDAR_SCOPE = ['https://www.googleapis.com/auth/calendar']

# # # Initialize the calendar API
# calendar_service = Google::Apis::CalendarV3::CalendarService.new
# calendar_service.client_options.application_name = 'Google Calendar API Ruby Quickstart'
# calendar_service.authorization = authorize_calendar

# ----------------------------------------------------------------------
#     ROUTES, END POINTS AND ACTIONS
# ----------------------------------------------------------------------

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

# basically after clicking on the add to slack button 
# it'll return back with a code as a parameter in the query string
# e.g. https://yourdomain.com/oauth?code=92618588033.110206495095.452e860e77&state=

# we need to make a POST request to Slack's API to get a more
# permanent token that we can use to make requests to the API
# https://slack.com/api/oauth.access 
# read also: http://blog.teamtreehouse.com/its-time-to-httparty

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
    
  else
    401
  end
  
end

# If successful this will give us something like this:
# {"ok"=>true, "access_token"=>"xoxp-92618588033-92603015268-110199165062-deab8ccb6e1d119caaa1b3f2c3e7d690", "scope"=>"identify,bot,commands,incoming-webhook", "user_id"=>"U2QHR0F7W", "team_name"=>"Programming for Online Prototypes", "team_id"=>"T2QJ6HA0Z", "incoming_webhook"=>{"channel"=>"bot-testing", "channel_id"=>"G36QREX9P", "configuration_url"=>"https://onlineprototypes2016.slack.com/services/B385V4V8E", "url"=>"https://hooks.slack.com/services/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"}, "bot"=>{"bot_user_id"=>"U37HMQRS8", "bot_access_token"=>"xoxb-109599841892-oTaxqITzZ8fUSdmMDxl5kraO"}

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

  redirect_to url_for(:action => :calendars)

end

get '/calendars' do

  client = Signet::OAuth2::Client.new(access_token: session[:access_token])

  service = Google::Apis::CalendarV3::CalendarService.new

  service.authorization = client

  @calendar_list = service.list_calendar_lists

end

# get '/authorize' do
#   # NOTE: Assumes the user is already authenticated to the app
#   user_id = request.session['user_id']
#   credentials = authorizer.get_credentials(user_id, request)
#   if credentials.nil?
#     redirect authorizer.get_authorization_url(login_hint: user_id, request: request)
#   end
#   # Credentials are valid, can call APIs
#   # ...
# end

# ----------------------------------------------------------------------
#     OUTGOING WEBHOOK
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

# JSON Payload:
# {
#   "actions": [
#     {
#       "name": "recommend",
#       "value": "yes"
#     }
#   ],
#   "callback_id": "comic_1234_xyz",
#   "team": {
#     "id": "T47563693",
#     "domain": "watermelonsugar"
#   },
#   "channel": {
#     "id": "C065W1189",
#     "name": "forgotten-works"
#   },
#   "user": {
#     "id": "U045VRZFT",
#     "name": "brautigan"
#   },
#   "action_ts": "1458170917.164398",
#   "message_ts": "1458170866.000004",
#   "attachment_id": "1",
#   "token": "xAB3yVzGS4BQ3O9FACTa8Ho4",
#   "original_message": "{\"text\":\"New comic book alert!\",\"attachments\":[{\"title\":\"The Further Adventures of Slackbot\",\"fields\":[{\"title\":\"Volume\",\"value\":\"1\",\"short\":true},{\"title\":\"Issue\",\"value\":\"3\",\"short\":true}],\"author_name\":\"Stanford S. Strickland\",\"author_icon\":\"https://api.slack.comhttps://a.slack-edge.com/bfaba/img/api/homepage_custom_integrations-2x.png\",\"image_url\":\"http://i.imgur.com/OJkaVOI.jpg?1\"},{\"title\":\"Synopsis\",\"text\":\"After @episod pushed exciting changes to a devious new branch back in Issue 1, Slackbot notifies @don about an unexpected deploy...\"},{\"fallback\":\"Would you recommend it to customers?\",\"title\":\"Would you recommend it to customers?\",\"callback_id\":\"comic_1234_xyz\",\"color\":\"#3AA3E3\",\"attachment_type\":\"default\",\"actions\":[{\"name\":\"recommend\",\"text\":\"Recommend\",\"type\":\"button\",\"value\":\"recommend\"},{\"name\":\"no\",\"text\":\"No\",\"type\":\"button\",\"value\":\"bad\"}]}]}",
#   "response_url": "https://hooks.slack.com/actions/T47563693/6204672533/x7ZLaiVMoECAW50Gw1ZYAXEM"
# }

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
        puts 'replace message'
        client.chat_postMessage(channel: channel, text: message, attachments: interactive_assignment_course, as_user: true)

      elsif action_name == "show today"

        client.chat_postMessage(channel: channel, text: "Showing today's schedule..", as_user: true)

      elsif action_name == "show next"
        calendar_upcoming_events $service
        client.chat_postMessage(channel: channel, text: get_upcoming_events($service), as_user: true) 
      
      else
        200
        # client.chat_postMessage(channel: channel, text: replace_message, as_user: true)
      end

  elsif call_back == "course_assignment"

    if action_name == "add course"
      $course_object = {}
      client.chat_postMessage(channel: channel, text: "Enter Course Name starting with ~course name: ~", as_user: true)
    else
      message = "You're adding an assignment for #{action_name}!"
      $course_object={}
      $assignment_record = "For #{action_name}: "
      $course_object.course_name = action_name
      client.chat_postMessage(channel: channel, text: message, attachments: [{"text": "Please type your assignment details in <= 140 chars", "callback_id": "assignment_text"}].to_json, as_user: true)
    end  
  
  else
    200

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
 
# def add_jude
#   [
#     {
#       "text" : "Add Jude to Slack",
#       "callback_id" : "add jude",
#       "fallback" : "Add Jude via Button",
#       "actions" :
#       [
#         {
#             "name":  "add-jude",
#             "text":  "Add Jude to Slack",
#             "type":  "button"
#             }
#       ]
#         }    
#   ].to_json
# end

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

#Oauth for Calendar API
def auth_calendar

  # client_id = Google::Auth::ClientId.from_file('/client_secrets.json')
  # scope = ['https://www.googleapis.com/auth/calendar']
  # token_store = Google::Auth::Stores::RedisTokenStore.new(redis: Redis.new)
  # authorizer = Google::Auth::WebUserAuthorizer.new(
  #             client_id, scope, token_store, '/oauth2callback')
  
  client = Signet::OAuth2::Client.new({
    client_id: ENV['CALENDAR_CLIENT_ID'],
    client_secret: ENV['CALENDAR_CLIENT_SECRET'],
    authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
    scope: Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY,
    redirect_uri: "https://agile-stream-68169.herokuapp.com/oauthcallback"
  })

  redirect_to client.authorization_uri.to_s

end

def authorize_calendar
  # FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file('/client_secret.json')
  scope = ['https://www.googleapis.com/auth/calendar']
  token_store = Google::Auth::Stores::RedisTokenStore.new(redis: Redis.new)
  # token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(
    client_id, CALENDAR_SCOPE, token_store,'/oauth2callback')

  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(
      base_url: OOB_URI)
    system("open", url)
    # Launchy.open(url)
    # code = HTTParty.get url
    # puts "Open the following URL in the browser and enter the resulting code after authorization."
    # puts url
    # code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI)
  end
  credentials
end