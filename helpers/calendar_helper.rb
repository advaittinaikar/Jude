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

		service = Google::Apis::CalendarV3::CalendarService.new
		service.client_options.application_name = ENV['CALENDAR_APPLICATION_NAME']
		service.authorization = client

		return service
	end

  #METHOD: Redirects user to Oauth page for the Calendar API authorisation. 
	def auth_calendar
	  
		client = Signet::OAuth2::Client.new({
 
		    client_id: ENV['CALENDAR_CLIENT_ID'],
		    client_secret: ENV['CALENDAR_CLIENT_SECRET'],
		    authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
        token_credential_uri:  'https://accounts.google.com/o/oauth2/token',
        scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
		    redirect_uri: "https://agile-stream-68169.herokuapp.com/oauthcallback"
	  	})

		redirect to(client.authorization_uri.to_s)
	end
	
	#METHOD: Gets a list of events from Google Calendar using Calendar List.
  def calendars

	  client = Signet::OAuth2::Client.new(access_token: $access_token)

	  service = Google::Apis::CalendarV3::CalendarService.new

	  service.authorization = client

	  @calendar_list = service.list_calendar_lists
	end

	#METHOD: Creates an event in Google Calendar. 
	#Returns a success message when done.
  def create_calendar_event (assignment,team)

    access_token = team["calendar_token"]
    access_code = team["calendar_code"]

    client = Signet::OAuth2::Client.new(access_token: $access_token)

    client.update!(
      :code => access_code,
      :access_token => access_token,
      :expires_in => 9000
      )

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    # event_description = "Test."

    # event = Google::Apis::CalendarV3::Event.new{
    #   summary : 'Google I/O 2015',
    #   location : '800 Howard St., San Francisco, CA 94103',
    #   description : 'A chance to hear more about Google\'s developer products.',
    #   start: {
    #     date_time : '2016-12-28T09:00:00-07:00',
    #     time_zone : 'America/Los_Angeles',
    #   },
    #   end: {
    #     date_time : '2016-12-28T17:00:00-07:00',
    #     time_zone : 'America/Los_Angeles',
    #   },
    #   recurrence : [
    #     'RRULE:FREQ=DAILY;COUNT=2'
    #   ],
    #   attendees : [
    #     {email : 'lpage@example.com'},
    #     {email : 'sbrin@example.com'},
    #   ],
    #   reminders : {
    #     use_default : false,
    #     overrides : [
    #       {method => 'email', 'minutes: 24 * 60'},
    #       {method => 'popup', 'minutes: 10'},
    #     ],
    #   },
    # }

    # result = client.insert_event('primary', event)
    puts "Event created: #{result.html_link}"

  end

  #METHOD: Gets next 10 events in a user's Google Calendar
  def get_upcoming_events team

    access_token = team["calendar_token"]
    access_code = team["calendar_code"]

    client = Signet::OAuth2::Client.new( access_token: access_token )

    client.expires_in = Time.now + 1_000_000
    # client.update!(
    #   :code => access_code,
    #   :access_token => access_token,
    #   :expires_in => 9000
    # )

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

  end
end