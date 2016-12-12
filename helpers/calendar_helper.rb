module Sinatra
  module CalendarHelper

  	#Initialising the API by creating a Calendar Service
  	def intialize_api

      $service = Google::Apis::CalendarV3::CalendarService.new
      $service.client_options.application_name = ENV['CALENDAR_APPLICATION_NAME']
      $service.authorization = auth_calendar

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

	  redirect client.authorization_uri.to_s

	end

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

    def calendars

	  client = Signet::OAuth2::Client.new(access_token: session[:access_token])

	  service = Google::Apis::CalendarV3::CalendarService.new

	  service.authorization = client

	  @calendar_list = service.list_calendar_lists

	end

    # def create_calendar_event (assignment, service)

    #   event = Google::Apis::CalendarV3::Event.new{
    #     description : assignment['description'],
    #     start : {
    #       date_time : assignment['due_date'],
    #       time_zone : 'America/New_York',
    #       },
    #     end: {
    #       date_time : assignment['due_date'],
    #       time_zone : 'America/New_York',
    #       },
    #     reminders: {
    #       use_default: true,
    #     }
    #   }

    #   result = service.insert_event('primary', event)

    #   return "Successfully added to your calendar!"

    # end

    # Gets next 10 events in a user's Google Calendar
    def get_upcoming_events service
      response = service.list_events('primary',
                               max_results: 10,
                               single_events: true,
                               order_by: 'startTime',
                               time_min: Time.now.iso8601)

      message="Your upcoming 10 events are:"

      respond.items.each do |event|
        message+="\n#{event.summary} on #{event.start.date}"
      end

      return message   
    end

    # get '/oauthcallback' do

	#   client = Signet::OAuth2::Client.new({

	#     client_id: ENV['CALENDAR_CLIENT_ID'],
	#     client_secret: ENV['CALENDAR_CLIENT_SECRET'],
	#     authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
	#     redirect_uri: "https://agile-stream-68169.herokuapp.com/oauthcallback",
	#     code: params[:code]

	#   })

	#   response = client.fetch_access_token!

	#   session[:access_token] = response['access_token']

	#   redirect url_for(:action => :calendars)

	# end

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

  end
end