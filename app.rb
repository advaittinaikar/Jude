require "sinatra"
require 'sinatra/activerecord'
require 'rake'
require 'active_support/all'
require "active_support/core_ext"

require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/api_client/client_secrets'
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
$access_token = nil
$access_code = ""
$response

# enable sessions for this project
enable :sessions

# ----------------------------------------------------------------------
#     ROUTES, END POINTS AND ACTIONS
# ----------------------------------------------------------------------

#
get "/" do
  haml :index
  # "Assignments table is: <br>" + Assignment.all.to_json + "<br>" +
  # "Courses table is: <br>" + Course.all.to_json + "<br>" + 
  # "Events table is: <br>" + Event.all.to_json
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
  
  slack_oauth_request = "https://slack.com/api/oauth.access"
  
  if code
    $response = HTTParty.post slack_oauth_request, body: {client_id: ENV['SLACK_CLIENT_ID'], client_secret: ENV['SLACK_CLIENT_SECRET'], code: code}
    
    puts $response.to_s
    
    # We can extract lots of information from this web hook... 
    
    access_token = $response["access_token"]
    team_name = $response["team_name"]
    team_id = $response["team_id"]
    user_id = $response["user_id"]
        
    incoming_channel = $response['incoming_webhook']['channel']
    incoming_channel_id = $response['incoming_webhook']['channel_id']
    incoming_config_url = $response['incoming_webhook']['configuration_url']
    incoming_url = $response['incoming_webhook']['url']
    
    bot_user_id = $response['bot']['bot_user_id']
    bot_access_token = $response['bot']['bot_access_token']
    
    # Storing user and team details into the database
    team = Team.find_or_create_by( team_id: team_id, user_id: user_id )
  
    team.access_token = access_token
    team.team_name = team_name
    team.raw_json = $response.to_s
    team.incoming_channel = incoming_channel
    team.incoming_webhook = incoming_url
    team.bot_token = bot_access_token
    team.bot_user_id = bot_user_id
    team.save!

    # team = Team.find_or_create_by( team_id: team_id, user_id: user_id )

    if team["calendar_code"].nil?
      auth_calendar
    else
      sign_up_greeting
    end
    
  else
    401
  end
  
end

#ENDPOINT: The redirect_url entered in Google Console. 
#Google Oauth redirects to this endpoint once user has authorised request.
get '/oauthcallback' do

  team_id = $response["team_id"]
  user_id = $response["user_id"]

  team = Team.find_by( user_id: user_id )
  team.calendar_code = params[:code]
  team.save!

  client = Signet::OAuth2::Client.new(
  {
      client_id: ENV['CALENDAR_CLIENT_ID'],
      client_secret: ENV['CALENDAR_CLIENT_SECRET'],
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
      token_credential_uri:  'https://accounts.google.com/o/oauth2/token',
      redirect_uri: "https://agile-stream-68169.herokuapp.com/oauthcallback",
      grant_type: "authorization_code",
      access_type: "offline",
      code: params[:code]
    }
      )

  response = client.fetch_access_token!

  puts "The response after first authorization is #{response}"

  if response
    team.calendar_token = response['access_token']
    team.calendar_refresh_token = response['refresh_token']
    team.save!

    puts "The token for Google Calendar API is: #{response['access_token']}"
    
    #Final response to user!
    sign_up_greeting
  else
    "Something went wrong in setting up your calendar and slack.<br>We'd appreciate it if you could try again!" 
  end

end

# ----------------------------------------------------------------------
#     OUTGOING WEBHOOK FROM SLACK
# ----------------------------------------------------------------------

#ANY EVENT HANDLING: Endpoint for an event subscription

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

#BUTTON INTERACTION HANDLING: Endpoint for an interactive message interaction. Control center for all button interactions.

post '/interactive-buttons' do

  content_type :json

  request.body.rewind
  raw_body = request.body.read

  # puts "Params: " + params.to_s
  
  json_request = JSON.parse( params["payload"] )
  # puts "JSON = " + json_request.to_s
  puts "checking token"

  respond_to_slack_button json_request
end

# ----------------------------------------------------------------------
#     METHODS
# ----------------------------------------------------------------------

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
  
  team = Team.find_by(team_id: team_id)
  
  # didn't find a match... this is junk! 
  return if team.nil?
  
  # see if the event user is the bot user 
  # if so we shoud ignore the event
  return if team.bot_user_id == event_user
  
  event = Event.create(team_id: team_id, type_name: event_type, user_id: event_user, text: event_text, channel: event_channel, timestamp: Time.at(event_ts.to_f) )
  event.team = team
  event.save!
  
  client = team.get_client
  
  event_to_action client, event, team
end

#METHOD: Responds to a slack button click that is passed to the "/interactive-buttons" endpoint.
# => Responds with message posts
def respond_to_slack_button json

  if json['token'] != ENV['SLACK_VERIFICATION_TOKEN']
      halt 403, 'Incorrect slack token'
  end
  
  puts "token valid"

  call_back = json['callback_id']
  action_name = json['actions'].first["name"]
  action_text = json['actions'].first["text"]
  action_value = json['actions'].first["value"]
  channel = json['channel']['id']
  team_id = json['team']['id']
  user_id = json['user']['id']
  time_stamp = json['message_ts']
  
  team = Team.find_by(user_id: user_id)
  puts team

  if team.nil?
    client.chat_postMessage(channel: channel, text:"You don't have Jude installed. Click the below link to install: http://agile-stream-68169.herokuapp.com/", unfurl_links: true)
    return
  end
  
  puts "team found!"
  
  client = team.get_client

  event = Event.create(team_id: team_id, type_name: "button_click", user_id: user_id, text: action_text, channel: channel, timestamp: Time.at(time_stamp.to_f) )
  event.team = team
  event.save!

  case call_back
    when 'to-do'
  
        message = "Great! "
      
        case action_name 
          when "add"

              $assignment_record = ""
              message += "Let's add an assignment!"
              client.chat_postMessage(channel: channel, text: message, attachments: interactive_assignment_course, as_user: true)
              {  text: "You selected 'add an assignment'" , replace_original: true }.to_json

          when "show assignments"

              message = get_upcoming_assignments team
              client.chat_postMessage(channel: channel, text: message, as_user: true) 
              {  text: "You selected 'show upcoming assignments'" , replace_original: true }.to_json

          when "show next"

              message = get_upcoming_events team
              client.chat_postMessage(channel: channel, text: message, as_user: true)
              {  text: "You selected 'show upcoming schedule'" , replace_original: true }.to_json

          else
              # client.chat_postMessage(channel: channel, text: replace_message, as_user: true)
              200
          end

    when "course_assignment"

        if action_name == "add course"
          client.chat_postMessage(channel: channel, text: "Enter Course Name starting with *course name: *", as_user: true)
          {  text: "You selected 'add a course'" , replace_original: true }.to_json
        else
          message = "You're adding an assignment for #{action_name}!"
          
          $assignment_record = "Assignment for #{action_name}: "
          $assignment_object["course_name"] = action_name
          client.chat_postMessage(channel: channel, text: message, attachments: [{"text": "Please type your assignment details in <= 140 chars", "callback_id": "assignment_text"}].to_json, as_user: true)
        
          {  text: "You selected 'add an assignment'" , replace_original: true }.to_json
        end  
  
    when "add event"

        if action_name == "add assignment"

          $assignment_record = ""
          
            client.chat_postMessage(channel: channel, text: "Let's add an assignment!", attachments: interactive_assignment_course, as_user: true)
            {  text: "You selected 'add an assignment'" , replace_original: true }.to_json

        elsif action_name == "add course"

          client.chat_postMessage(channel: channel, text: "Enter Course Name starting with *course name: *", as_user: true)
          {  text: "You selected 'add a course'" , replace_original: true }.to_json

        else
          
          200

        end

    when "confirm_assignment"

        if action_name == "confirm"

          create_calendar_event team

          client.chat_postMessage(channel: channel, text: "The assignment has been added to your Google Calendar.", as_user: true)
          {  text: "The assignment has been added to your Google Calendar." , replace_original: true }.to_json
          
        else

          client.chat_postMessage(channel: channel, text: "Add assignment", attachments: interactive_assignment_course, as_user: true)
          {  text: "Please add the assignment again!" , replace_original: true }.to_json

        end

    when "confirm_course"

        if action_name == "confirm"
s
          create_course $course_object
          client.chat_postMessage(channel: channel, text: "The course has been added to your list of courses.", as_user: true)
          {  text: "The course has been added to your list of courses." , replace_original: true }.to_json
        
        else

          client.chat_postMessage(channel: channel, text: "Enter Course Name starting with *course name: *", as_user: true)
          {  text: "Please add the course again!" , replace_original: true }.to_json

        end

    else
      200
    # do nothing... 
  end
end

def sign_up_greeting
  "#{Team.all.to_json}<br>Jude has been successfully installed.<br>Your Calendar has been already been synced with Jude.<br>Please login to your Slack team to meet Jude!"
end

# ----------------------------------------------------------------------
#     ERRORS
# ----------------------------------------------------------------------

error 401 do
  "Invalid response or malformed request"
end