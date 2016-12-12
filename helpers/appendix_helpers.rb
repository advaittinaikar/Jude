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