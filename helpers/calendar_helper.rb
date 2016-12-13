module Sinatra
  module CalendarHelper

  	# ----------------------------------------------------------------------
	#     ROUTES AND END POINTS
	# ----------------------------------------------------------------------

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

	  # session[:code] = client.code

	  response = client.fetch_access_token!

	  session[:access_token] = response['access_token']

	  calendar_list = calendars

	end

	#The Authorization url which checks if credentials are valid.
	get '/authorize' do
	  # NOTE: Assumes the user is already authenticated to the app
	  user_id = request.session['user_id']
	  credentials = authorizer.get_credentials(user_id, request)
	  if credentials.nil?
	    redirect authorizer.get_authorization_url(login_hint: user_id, request: request)
	  end
	  # Credentials are valid, can call APIs
	  # ...
	end

	# ----------------------------------------------------------------------
	#     METHODS
	# ----------------------------------------------------------------------

	#METHOD: Initialises the API by creating a Calendar service
  	def intialize_api

      $service = Google::Apis::CalendarV3::CalendarService.new
      $service.client_options.application_name = ENV['CALENDAR_APPLICATION_NAME']
      $service.authorization = auth_calendar

    end

    #METHOD: Initialises the API by creating a Calendar service
    def authorization_complete

    end

    #METHOD: Redirects user to Oauth page for the Calendar API authorisation. 
	def auth_calendar
	  
		client = Signet::OAuth2::Client.new({

		    client_id: ENV['CALENDAR_CLIENT_ID'],
		    client_secret: ENV['CALENDAR_CLIENT_SECRET'],
		    authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
		    redirect_uri: "https://agile-stream-68169.herokuapp.com/oauthcallback"
	  	})

		redirect to(client.authorization_uri.to_s)

	end
	
	#METHOD: Create a signet client to be used for Oauth. Takes optional argument code, the oauth returned code
	def create_signet_client *code

		client = Signet::OAuth2::Client.new({

		    client_id: ENV['CALENDAR_CLIENT_ID'],
		    client_secret: ENV['CALENDAR_CLIENT_SECRET'],
		    authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
		    redirect_uri: "https://agile-stream-68169.herokuapp.com/oauthcallback",
		    code: code

	  	})

	  	return client

	end

	#METHOD: Gets a list of events from Google Calendar using Calendar List.
    def calendars

	  client = Signet::OAuth2::Client.new(access_token: session[:access_token])

	  service = Google::Apis::CalendarV3::CalendarService.new

	  service.authorization = client

	  @calendar_list = service.list_calendar_lists

	end

	#METHOD: Creates an event in Google Calendar. 
	#Returns a success message when done.
    def create_calendar_event (assignment, service)

      event = Google::Apis::CalendarV3::Event.new{
        description: assignment['description'],
        start: {
          date_time: assignment['due_date'],
          time_zone: 'America/New_York',
          },
        end: {
          date_time: assignment['due_date'],
          time_zone: 'America/New_York',
          },
        reminders: {
          use_default: true,
        }
      }

      result = service.insert_event('primary', event)

      return "Successfully added to your calendar!"

    end

    #METHOD: Gets next 10 events in a user's Google Calendar
    def get_upcoming_events service
      response = service.list_events('primary',
                               max_results: 10,
                               single_events: true,
                               order_by: 'startTime',
                               time_min: Time.now.iso8601)

      message="Your upcoming 10 events are:"

      response.items.each do |event|
        message+="\n#{event.summary} on #{event.start.date}"
      end

      return message   
    end

    #METHOD: Hardcoded. Gets next few events in user's Google Calendar.
    def show_next_events
	  message =  "Upcoming Events:
	              1. Pay rent [2016-12-25]\n
	              2. Travel for vacation [2016-12-29]\n
	              3. New Year's Eve Party [2016-12-31]\n"
	  return message
	end

  end
end