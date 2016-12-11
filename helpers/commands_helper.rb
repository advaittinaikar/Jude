module Sinatra
  module CommandsHelper
  
    # ------------------------------------------------------------------------
    # =>   A LIST OF ACTIONS
    # ------------------------------------------------------------------------

    @@jude_bot_commands = [
      { message: "*add* - Helps add an assignment to your calendar", is_admin: false },
      { message: "*help* - Provides help on different features", is_admin: false },
      { message: "*about* - Tells you the story of Jude", is_admin: false }
    ]

    @@error_counter = 0
    
    # ------------------------------------------------------------------------
    # =>   MAPS THE CURRENT EVENT TO AN ACTION
    # ------------------------------------------------------------------------
    
    def event_to_action client, event
      
      ef = event.formatted_text
      puts event
      puts "Formatted Text: #{event.formatted_text}"
      
      return if ef.nil?
      
      is_admin = is_admin_or_owner client, event
        
      # Hi Commands
      if ["hi","hello","hey","heyy"].any? { |w| ef.starts_with? w }
      message = interactive_greeting
        client.chat_postMessage(channel: event.channel, text: "Hello there. Let's get something done today.", attachments: message, as_user:true)

      # Handle the Help commands
      elsif ef.include? "help"
        client.chat_postMessage(channel: event.channel, text: get_commands_message( is_admin ), as_user: true)

      # Respond to thanks message
      elsif ef.starts_with? "thank"
        client.chat_postMessage(channel: event.channel, text: "That's mighty nice of you. You're welcome and thank you for having me!", as_user: true)

      #   
      elsif ef.starts_with? "details"
        assignment_text = ef.slice! "details: "
        $assignment_record += " " + assignment_text
        client.chat_postMessage(channel: event.channel, text: "So when is this assignment due?", as_user: true)

      elsif ef.starts_with? "due: "
        unformatted_date = ef(9..(ef.length-1).slice! "due: "
        due_date = Kronic.parse(unformatted_date)
        # $assignment_record + = " due on" + assignment_text
        puts $assignment_record
        client.chat_postMessage(channel: event.channel, text: "So your assignment is #{$assignment_record}, due #{unformatted_date} ( #{due_date} )", as_user: true)

      elsif event.formatted_text == "show"
        events_message = get_upcoming_events calendar_service
        client.chat_postMessage(channel: event.channel, text: events_message, as_user: true)

      elsif event.formatted_text == "add"
        buttons = message_add_event
        client.chat_postMessage(channel: event.channel, text:"Add to your calendar", attachments:buttons)

      else

        # ERROR Commands
        # not understood or an error
        puts "Error Counter #{ @@error_counter }"
        
        @@error_counter += 1

        if @@error_counter > 10
          client.chat_postMessage(channel: event.channel, text: "This is really fishy now. You aren't normally like this. Please be nice or type `help` to find my commands.", as_user: true)
        elsif @@error_counter > 6 and @@error_counter <= 10
          client.chat_postMessage(channel: event.channel, text: "Hmmm, you seems to be different today. Hope all is well. Anyways, type `help` to find my commands.", as_user: true)  
        else  
          client.chat_postMessage(channel: event.channel, text: "I didn't get that but that's alright. If you're stuck, type `help` to find my commands.", as_user: true)
        end
        
      end
      
    end
    
    # Converts the list of commands to a message
    def get_commands_message is_admin = false
      
        message = "*JudeBot* - This bot helps you add assignments to your calendar.\n"
        message += "*Commands:* \n"
      
        @@jude_bot_commands.each do |c|
          if c[:is_admin] == false or (c[:is_admin] == true and is_admin)
            message += c[:message] + "\n"
          end
        end

        message

    end

    # Gets useful user information from Slack
    def get_user_name client, event
      # calls users_info on slack
      info = client.users_info(user: event.user_id ) 
      info['user']['name']
    end
    
    def is_admin_or_owner client, event
      # calls users_info on slack
      info = client.users_info(user: event.user_id ) 
      info['user']['is_admin'] || info['user']['is_owner']
    end

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

    # Button attachment message when user says hi
    def interactive_greeting

      [
        {
          "text": "What would you like to do today?",
          "fallback": "You're missing out on a great experience!",
          "callback_id": "to-do",
          "attachment_type": "default",
          "actions": [
            {
              "name":  "add",
              "text":  "Add assignment",
              "type":  "button",
              "value": "add"
              },
            {
              "name":  "show today",
              "text":  "Show Today's schedule",
              "type":  "button",
              "value": "show-today"
              },
            {
              "name":  "show next",
              "text":  "Show Next 10 events",
              "type":  "button",
              "value": "show-next"
              }  
          ]
        }
      ].to_json

    end

    def interactive_assignment_course
      [
        {
          "text": "Which course is the assignment for?",
          "callback_id": "course_assignment",
          "fallback": "Type your course number",
          "actions":[
            {
              "name": "dfe",
              "text": "Design for environment",
              "type": "button"
            },
            {
              "name": "vp",
              "text": "Visual processes",
              "type": "button"
            },
            {
              "name": "pop",
              "text": "Programming for Online Prototypes",
              "type": "button"
            }
          ]

        }
      ].to_json

    end

    # def interactive_assignment_due

    #   [
    #     {
    #       "text": "Which course is the assignment for?",
    #       "callback_id": "course_assignment",
    #       "fallback": "Type your course number",
    #       "actions":[
    #         {
    #           "name": "dfe",
    #           "text": "Design for environment",
    #           "type": "button"
    #         },
    #         {
    #           "name": "vp",
    #           "text": "Visual processes",
    #           "type": "button"
    #         },
    #         {
    #           "name": "pop",
    #           "text": "Programming for Online Prototypes",
    #           "type": "button"
    #         }
    #       ]

    #     }
    #   ].to_json

    # end
  end
  
end