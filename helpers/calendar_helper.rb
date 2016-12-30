module Sinatra
  module CalendarHelper

	# ----------------------------------------------------------------------
	#     METHODS
	# ----------------------------------------------------------------------

  	#METHOD: Create a signet client to be used for Oauth. Takes optional argument code, the oauth returned code
  	def create_calendar_service team
      access_token = team.access_token

  		client = Signet::OAuth2::Client.new(
        access_token: access_token 
        )

      client.expires_in = Time.now + 1_000_000

      if client
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

    #METHOD: Redirects user to Oauth page for the Calendar API authorisation. 
  	def auth_calendar
  	  
  		client = Signet::OAuth2::Client.new(
      {
  		   client_id: ENV['CALENDAR_CLIENT_ID'],
  		   client_secret: ENV['CALENDAR_CLIENT_SECRET'],
  		   authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
         token_credential_uri:  'https://accounts.google.com/o/oauth2/token',
         scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
  		   redirect_uri: "https://agile-stream-68169.herokuapp.com/oauthcallback"
  	  }
        )

  		redirect to client.authorization_uri.to_s
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

    #METHOD: Returns the next 20 assignments in calendar. 
    def get_upcoming_assignments team

      service = create_calendar_service team

      response = service.list_events('primary',
                               max_results: 20,
                               single_events: true,
                               order_by: 'startTime',
                               time_min: Time.now.iso8601)

      message= "Your upcoming assignments are:"

      response.items.each do |event,ind|
        if event.summary.include? "assignment" or "due"
          message+="#{event.summary} , due on #{event.start.date}"
        end
      end

      return message
    end

    #METHOD: Returns the next 20 event in calendar.
    def get_upcoming_events team

      access_token = team["calendar_token"]

      client = Signet::OAuth2::Client.new(access_token: access_token)

      client.expires_in = Time.now + 1_000_000

      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = client

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

    def refreshing_token team
      client = Signet::OAuth2::Client.new(
      {

          client_id: ENV['CALENDAR_CLIENT_ID'],
          client_secret: ENV['CALENDAR_CLIENT_SECRET'],
          scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
          token_credential_uri:  'https://accounts.google.com/o/oauth2/token',
          redirect_uri: "https://agile-stream-68169.herokuapp.com/oauthcallback",
          grant_type: refresh_token,
          refresh_token: team["calendar_refresh_token"]
        }
          )

      response = client.fetch_access_token!

      access_token = response['access_token']

      return access_token
    end

  end
end