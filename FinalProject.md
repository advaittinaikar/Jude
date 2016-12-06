<b>Project Abstract</b>

Weather, transit and daily schedule are the among the 3 most essential pieces of information required by any busy individual in the morning. And yet a user often has to open multiple apps to receive this information.

“The Multibot Daily delivers key updates of the day’s weather, transit details and user’s schedule through Telegram messages every morning.”

Weather and Transit information (eg: bus timings and traffic details) will be delivered daily based on the user’s configured settings. The user’s schedule day and week schedule can both be, along with sending push notifications for high priority projects at pre-defined time before the submission deadline.

The Multibot Daily is targeted at the busy tech-enabled youth who need essential information from the moment they wake up. The MultiBot uses Telegram’s bot functionality to obtain and delivered data from the following APIs:
1. Google Calendar API
2. weather.com's API
3. Google Maps Transit API
4. Google Contacts API

The motivation to build this micro-service is derived from my personal daily exasperations as a Graduate student. I have also noticed the need for such a services among colleagues and friends. Personal chat is the most ubiquitous medium, as opposed to SMS, Slack and Phone, and hence Telegram was chosen.

<b>Workflow Diagram</b>
<p>
<img src= "https://github.com/advaittinaikar/MyOwnSMSBot/blob/master/Workflow%20-%20Final%20Project.001.jpeg">
</p>

<b>Effort Priority Matrix</b>
<p>
<img src= "https://github.com/advaittinaikar/MyOwnSMSBot/blob/master/Effort%20Priority%20matrix.png">
</p>

<b>Work Flow Diagram</b>
<img src= "https://github.com/advaittinaikar/Spoon-Knife/blob/master/Workflow%20diagram.png">

<b>Technical Report</b>

APIs used

<b>Telegram</b>

Function: <i>Will be using the telegram bot as the user interface between the user and the heroku app.</i>

Authorizing the Bot: <i>Each bot is given a unique authentication token when it is created. The token looks something like 123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11</i>

Making requests: <i>All queries to the Telegram Bot API must be served over HTTPS and need to be presented in this form: https://api.telegram.org/bottoken/METHOD_NAME.</i>

Due to the lack of a reliable gem we will be using HTTParty to make the API request.

Telegram supports simple REST APIs (GET and POST HTTP methods) in 4 ways:
URL query string
application/x-www-form-urlencoded
application/json (except for uploading files)
multipart/form-data (use to upload files)
The response contains a JSON object.

Webhooks: <i>Using webhooks, one can perform a request to the Bot API while sending an answer to the webhook. Use either application/json or application/x-www-form-urlencoded or multipart/form-data response content type for passing parameters</i>

Getting Updates: <i>Create a Telegram object and use the various methods like getUpdates, setWebhook etc.</i>


<b>Accuweather</b>

Function: <i>To provide weather data at a certain time, as well as a daily forecast. User can also check weather at different locations. Weather message will also have a link to accuweather’s website.</i>

API access: 
<i>Accuweather allows location key searching or text searching. We will be using text searching with the input string as the city name. Steps:
1. Access database to see which is the current city being lived in
2. Extract location key of city
3. Access Accuweather API to receive weather forecasts</i>

Due to the lack of a reliable gem we will be using HTTParty to make the API request.

Code example:
Input: http://api.accuweather.com/currentconditions/v1/335315.json?apikey={your key}

Response: 
[
{
    LocalObservationDateTime: "2012-09-20T15:25:00-04:00",
    EpochTime: 1348169100,
    WeatherText: "Partly Sunny",
    WeatherIcon: 3,
    IsDayTime: true,
    Temperature: 
    {
        Metric: 
        {
            Value: "18.9",
            Unit: "C",
            UnitType: 17
        },
        Imperial: 
        {
            Value: "66",
            Unit: "F",
            UnitType: 18
        }
    },
    MobileLink: "http://m.accuweather.com/en/us/state-college-pa/16801/current-weather/335315?lang=en-us",
    Link: "http://www.accuweather.com/en/us/state-college-pa/16801/current-weather/335315?lang=en-us"
}
]

All necessary data of current conditions and mobile link is available in the JSON object returned.

<b>Google GTFS</b>

Function: <i>Retrieve data of the transit time and modes of transport for travel between user’s home and work locations</i>

API Access:
1. Install GTFS (General Transit Feed Specification) gem “gem install gtfs-realtime-bindings"
2. Create a transit object to get data from Google Transit
3. Data returned in a JSON object

Code Sample:
require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'

data = Net::HTTP.get(URI.parse("URL OF YOUR GTFS-REALTIME SOURCE GOES HERE"))
feed = Transit_realtime::FeedMessage.decode(data)
for entity in feed.entity do
  if entity.field?(:trip_update)
    p entity.trip_update
  end
end


<b>Google Calendar API</b>

Function: <i>Retrieve data of the transit time and modes of transport for travel between user’s home and work locations</i>

API Access:<i>
1. Turn on Google Calendar API
2. Install the Google Client Library “gem install google-api-client”
3. Set up the code
</i>	
Code Sample:
require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Google Calendar API Ruby Quickstart'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "calendar-ruby-quickstart.yaml")
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY

………
