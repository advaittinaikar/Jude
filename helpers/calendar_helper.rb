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

      if access_token_valid(access_token)
        client = Signet::OAuth2::Client.new( access_token: access_token )
    		service = Google::Apis::CalendarV3::CalendarService.new
    		service.client_options.application_name = ENV['CALENDAR_APPLICATION_NAME']
    		service.authorization = client
      else
        client = refreshing_token team
        service = Google::Apis::CalendarV3::CalendarService.new
        service.client_options.application_name = ENV['CALENDAR_APPLICATION_NAME']
        service.authorization = client
      end

  		return service
  	end

  	#METHOD: Creates an event in Google Calendar.
    def create_calendar_event team, assignment

      service = create_calendar_service team
      assignment_record = "Assignment for #{assignment["course_name"]}: #{assignment["description"]}"

      event = Google::Apis::CalendarV3::Event.new(
      {
            summary: assignment_record,
            start:{
              date: assignment["due_date"],
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
        if event.summary.to_s.include? "assignment"
          message+="#{event.summary}, due on #{event.start.date}\n"
        end 
      end

      return message
    end

    #METHOD: Returns the next 10 events in calendar.
    def get_upcoming_events team

      Event.last(5).to_json
      # service = create_calendar_service team

      # response = service.list_events('primary',
      #                          max_results: 10,
      #                          single_events: true,
      #                          order_by: 'startTime',
      #                          time_min: Time.now.iso8601)

      # message= "Your upcoming 10 events are:"

      # count = 1
      # response.items.each do |event|
      #   message+="#{count}. #{event.summary} on #{event.start.date}\n"
      #   count += 1
      # end

      # message
    end

    #METHOD: Refreshes and returns a new access token.
    def refreshing_token team

      client = Signet::OAuth2::Client.new(
      {
         client_id: ENV['CALENDAR_CLIENT_ID'],
         client_secret: ENV['CALENDAR_CLIENT_SECRET'],
         token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
         redirect_uri: "https://agile-stream-68169.herokuapp.com/oauthcallback",
         grant_type: 'refresh_token',
         refresh_token: team["calendar_refresh_token"]
        }
          )

      access_token = client.fetch_access_token!['access_token']

      client.update!(access_token: access_token)

      client
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