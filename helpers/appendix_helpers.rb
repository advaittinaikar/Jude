# require 'google/apis/calendar_v3'
# require 'googleauth'
# require 'googleauth/stores/file_token_store'
# require 'googleauth/web_user_authorizer'
# require 'googleauth/stores/redis_token_store'
# require 'logger'

# ----------------------------------------------------------------------
#     SLASH COMMANDS
# ----------------------------------------------------------------------

# TEST LOCALLY LIKE THIS:
# curl -X POST http://127.0.0.1:9393/queue_status -F token=9GCx7G3WrHix7EJsP818YOVB -F team_id=T2QJ6HA0Z 

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

# Button attachment message when user types "add"
    def message_add_event
      
      [
        {
            "text": "What would you like to add?",
            "fallback": "Sorry could not add that.",
            "callback_id": "add_event_button",
            "color": "#3AA3E3",
            "attachment_type": "default",
            "actions": [
                {
                    "name": "assignment",
                    "text": "Assignment",
                    "type": "button",
                    "value": "assignment"
                },
                {
                    "name": "lecture",
                    "text": "Lecture",
                    "type": "button",
                    "value": "lecture"
                },
                {
                    "name": "meeting",
                    "text": "Meeting",
                    "type": "button",
                    "value": "meeting"
                }
                ]
            }
       
      ].to_json

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


#--------------------------------------------------------

#EVENT Returned JSON looks like this

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

#--------------------------------------------------------

# def authorize_calendar
#   # FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

#   client_id = Google::Auth::ClientId.from_file('/client_secret.json')
#   scope = ['https://www.googleapis.com/auth/calendar']
#   token_store = Google::Auth::Stores::RedisTokenStore.new(redis: Redis.new)
#   # token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
#   authorizer = Google::Auth::UserAuthorizer.new(
#     client_id, CALENDAR_SCOPE, token_store,'/oauth2callback')

#   user_id = 'default'
#   credentials = authorizer.get_credentials(user_id)
#   if credentials.nil?
#     url = authorizer.get_authorization_url(
#       base_url: OOB_URI)
#     system("open", url)
#     # Launchy.open(url)
#     # code = HTTParty.get url
#     # puts "Open the following URL in the browser and enter the resulting code after authorization."
#     # puts url
#     # code = gets
#     credentials = authorizer.get_and_store_credentials_from_code(
#       user_id: user_id, code: code, base_url: OOB_URI)
#   end
#   credentials
# end

#Add to Slack button in Slack Channel 
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

# #The Authorization url which checks if credentials are valid.
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

# If successful this will give us something like this:
# {"ok"=>true, "access_token"=>"xoxp-92618588033-92603015268-110199165062-deab8ccb6e1d119caaa1b3f2c3e7d690", "scope"=>"identify,bot,commands,incoming-webhook", "user_id"=>"U2QHR0F7W", "team_name"=>"Programming for Online Prototypes", "team_id"=>"T2QJ6HA0Z", "incoming_webhook"=>{"channel"=>"bot-testing", "channel_id"=>"G36QREX9P", "configuration_url"=>"https://onlineprototypes2016.slack.com/services/B385V4V8E", "url"=>"https://hooks.slack.com/services/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"}, "bot"=>{"bot_user_id"=>"U37HMQRS8", "bot_access_token"=>"xoxb-109599841892-oTaxqITzZ8fUSdmMDxl5kraO"}
