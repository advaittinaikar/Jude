module Sinatra
  module CalendarHelper

	# ----------------------------------------------------------------------
	#     METHODS
	# ----------------------------------------------------------------------

    #METHOD: Redirects user to Oauth page for the Calendar API authorisation. 
    def auth_calendar
      
      client = Signet::OAuth2::Client.new(
      {
         client_id: ENV['CALENDAR_CLIENT_ID'],
         client_secret: ENV['CALENDAR_CLIENT_SECRET'],
         authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
         token_credential_uri:  'https://accounts.google.com/o/oauth2/token',
         scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
         redirect_uri: "https://agile-stream-68169.herokuapp.com/oauthcallback",
         access_type: "offline",
         approval_prompt: "force"
      }
        )

      redirect to client.authorization_uri.to_s
    end

  	#METHOD: Creates and returns a calendar service to be used for accessing calendar.
  	def create_calendar_service team
      access_token = team["calendar_token"]

  		client = Signet::OAuth2::Client.new(
        access_token: access_token
        )

      client.expires_in = Time.now + 1_000_000

      if access_token_valid(access_token)
    		service = Google::Apis::CalendarV3::CalendarService.new
    		service.client_options.application_name = ENV['CALENDAR_APPLICATION_NAME']
    		service.authorization = client
      else
        access_token = refreshing_token team
        client = Signet::OAuth2::Client.new(access_token: access_token)
        service = Google::Apis::CalendarV3::CalendarService.new
        service.client_options.application_name = ENV['CALENDAR_APPLICATION_NAME']
        service.authorization = client
      end

  		return service
  	end

  	#METHOD: Creates an event in Google Calendar.
    def create_calendar_event team

      service = create_calendar_service team

      event = Google::Apis::CalendarV3::Event.new(
      {
            summary: $assignment_record,
            start:{
              date: $assignment_object["due_date"],
              time_zone: 'Asia/Kolkata',
            },
            end:{
              date: $assignment_object["due_date"],
              time_zone: 'Asia/Kolkata',
            },
            reminders:{
              use_default: false,
              }
      }
        )

      result = service.insert_event('primary', event)
      puts "Event created: #{result.html_link}"
    end

    #METHOD: Returns the next 10 assignments in calendar. 
    def get_upcoming_assignments team

      service = create_calendar_service team

      response = service.list_events('primary',
                               max_results: 20,
                               single_events: true,
                               order_by: 'startTime',
                               time_min: Time.now.iso8601)

      message= "Your upcoming assignments are:"

      response.items.each do |event|
        if event["summary"].include? "assignment"
          message+="#{event.summary}, due on #{event.start.date}\n"
        end
      end

      return message
    end

    #METHOD: Returns the next 10 events in calendar.
    def get_upcoming_events team

      service = create_calendar_service team

      response = service.list_events('primary',
                               max_results: 10,
                               single_events: true,
                               order_by: 'startTime',
                               time_min: Time.now.iso8601)

      message= "Your upcoming 10 events are:"

      response.items.each do |event,ind|
        message+="#{ind}. \n#{event.summary} on #{event.start.date}"
      end

      return message
    end

    #METHOD: Refreshes and returns a new access token.
    def refreshing_token team

      stored_user_credentials = {
          refresh_token: team["calendar_refresh_token"],
          access_token: team["calendar_token"],
      }

      client = Signet::OAuth2::Client.new(
      {
          client_id: ENV['CALENDAR_CLIENT_ID'],
          client_secret: ENV['CALENDAR_CLIENT_SECRET'],
          token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
          redirect_uri: "https://agile-stream-68169.herokuapp.com/oauthcallback",
          grant_type: refresh_token,
        }
          )

      client.update_token!(stored_user_credentials)

      response = client.fetch_access_token!

      access_token = response['access_token']

      return access_token
    end

    #METHOD: Checks if access token is valid.
    def access_token_valid access_token
      token_check_uri =  "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=" + access_token
      response = HTTParty.get token_check_uri

      puts "The token validation object is #{response}"

      if response["user_id"]
        return true
      else
        return false
      end
    end

  end
end