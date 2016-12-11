require "sinatra"
require 'sinatra/activerecord'
require 'rake'
require 'active_support/all'
require "active_support/core_ext"

#require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

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
#you add to the folder
#using the following syntax:
#require_relative './models/<model_name>'
#require_relative './models/team'

Dir["./models/*.rb"].each {|file| require file }

Dir["./helpers/*.rb"].each {|file| require file }


# helpers Sinatra::DateTimeHelper
# helpers Sinatra::OfficeHoursHelper
helpers Sinatra::CommandsHelper


# enable sessions for this project
enable :sessions

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
CALENDAR_SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY

# Initialize the calendar API
calendar_service = Google::Apis::CalendarV3::CalendarService.new
calendar_service.client_options.application_name = CALENDAR_APPLICATION_NAME
calendar_service.authorization = authorize_calendar

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



# ----------------------------------------------------------------------
#     OUTGOING WEBHOOK
# ----------------------------------------------------------------------

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

# This will look a lot like this: 
# {
#   "token": "9GCx7G3WrHix7EJsP818YOVB",
#   "team_id": "T2QJ6HA0Z",
#   "api_app_id": "A36PS6J72",
#   "event": {
#     "type": "message",
#     "user": "U2QHR0F7W",
#     "text": "g ddf;gkl;d fkg;ldfkg df",
#     "ts": "1480296595.000007",
#     "channel": "D37HZB04D",
#     "event_ts": "1480296595.000007"
#   },
#   "type": "event_callback",
#   "authed_users": [
#     "U37HMQRS8"
#   ]
# }

# TO TEST THIS LOCALLY USE THIS ... 
# DON"T INCLUDE IT IN DEVELOPMENT"

# CALL AS FOLLOWS
# curl -X POST http://127.0.0.1:9393/test_event -F token=9GCx7G3WrHix7EJsP818YOVB -F team_id=T2QJ6HA0Z -F event_type=message -F event_user=U2QHR0F7W -F event_channel=D37HZB04D -F event_ts=1480296595.000007 -F event_text='g ddf;gkl;d fkg;ldfkg df' 

post '/calendar_events' do

end

post "/test_event" do

  if params['token'] != ENV['SLACK_VERIFICATION_TOKEN']
      halt 403, 'Incorrect slack token'
  end
  
  team = Team.find_by( team_id: params[:team_id] )
  
  # didn't find a match... this is junk! 
  return if team.nil?
  
  # see if the event user is the bot user 
  # if so we shoud ignore the event
  return if team.bot_user_id == params[:event_user]
  
  event = Event.create( team_id: params[:team_id], type_name: params[:event_type], user_id: params[:event_user], text: params[:event_text], channel: params[:event_channel ], timestamp: Time.at(params[:event_ts].to_f) )
  event.team = team 
  event.save
  
  client = team.get_client
  
  content_type :json
  return event_to_action client, event 
  
end


# ----------------------------------------------------------------------
#     INTERACTIVE MESSAGES
# ----------------------------------------------------------------------

post "/message_actions" do 
  
end

# ----------------------------------------------------------------------
#     SLASH COMMANDS
# ----------------------------------------------------------------------

# TEST LOCALLY LIKE THIS:
# curl -X POST http://127.0.0.1:9393/queue_status -F token=9GCx7G3WrHix7EJsP818YOVB -F team_id=T2QJ6HA0Z 

post "/queue_status" do
  
  
  # check it's valid
  if ENV['SLACK_VERIFICATION_TOKEN'] == params[:token]
    
    team_id = params[:team_id]
    channel_name = params[:channel_name]
    user_name = params[:user_name]
    text = params[:text]
    
    current_queue = OfficeHoursQueue.where( team_id: team_id ) 
    attachments = []
  
    if current_queue.empty?
      message = "There's no one in the queue. Type `queue me` to add."
    else
      message = "There's #{ current_queue.length } people in the queue. Here's the next few:"
      current_queue.limit(3).each_with_index do |q, index|
        attachments << get_queue_attachment_for( q )
      end
    end

    # specify the return type as 
    # json
    content_type :json
    {text: message, attachments: attachments, response_type: "ephemeral" }.to_json
    
    
  else
    content_type :json
    {text: "Invalid Request", response_type: "ephemeral" }.to_json

  end
  
end

post "/attendance" do
  
  
end


# ----------------------------------------------------------------------
#     ERRORS
# ----------------------------------------------------------------------


error 401 do 
  "Invalid response or malformed request"
end


# ----------------------------------------------------------------------
#   METHODS
#   Add any custom methods below
# ----------------------------------------------------------------------

private

# for example 
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

def authorize_calendar
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file(CALENDAR_CLIENT_SECRETS)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(
    client_id, CALENDAR_SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(
      base_url: OOB_URI)
    puts "Open the following URL in the browser and enter the " +
         "resulting code after authorization"
    puts url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI)
  end
  credentials
end