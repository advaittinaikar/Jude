module Sinatra
  module CommandsHelper
  
    # ------------------------------------------------------------------------
    # =>   A LIST OF ACTIONS
    # ------------------------------------------------------------------------

    @@jude_bot_commands = [
      { message: "`add` - Helps add an assignment to your calendar", is_admin: false },
      { message: "`help` - Provides help on different features", is_admin: false },
      { message: "`about` - Tells you the story of Jude", is_admin: false }
    ]

    @@error_counter = 0
    
    # ------------------------------------------------------------------------
    # =>   MAPS THE CURRENT EVENT TO AN ACTION
    # ------------------------------------------------------------------------
    
    def event_to_action client, event, team
      
      ef = event.formatted_text
      puts "Formatted Text: #{ef}"
      
      return if ef.nil?
      
      is_admin = is_admin_or_owner client, event
      user_id = team["user_id"]

      user_events = Event.find(:all, :conditions => {:user_id => user_id})
      second_last_event = user_events[-2].to_json
      
      puts "Event is #{second_last_event} and user_id is #{user_id}"

      # Hi Commands
      if ["hi","hello","hey","heyy"].any? { |w| ef.starts_with? w }

        message = interactive_greeting
        client.chat_postMessage(channel: event.channel, text: "Hello there. I'm Jude. Let's get something done for you today.", attachments: message, as_user:true)
        add_outgoing_event team, "interaction", "first greeting"

      elsif ef.starts_with? "about"
        
        client.chat_postMessage(channel: event.channel, text: "_#{about_jude}_", attachments: message, as_user:true)
        add_outgoing_event team, "message", "about command"
            
      # Handle the Help commands
      elsif ef.include? "help"

        client.chat_postMessage(channel: event.channel, text: get_commands_message( is_admin ), as_user: true)
        add_outgoing_event team, "message", "help command"

      # Respond to thanks message
      elsif ef.starts_with? "thank"

        client.chat_postMessage(channel: event.channel, text: "That's mighty nice of you. You're welcome and thank you for having me!", as_user: true)
        add_outgoing_event team, "message", "thanks command"

      elsif ef.starts_with? "details:"

        ef.slice!(0..8)
        $assignment.description = ef
        puts $assignment_record
        client.chat_postMessage(channel: event.channel, text: "So when is this assignment due?", as_user: true)

      elsif ef.starts_with? "due:"

        ef.slice!(0..4)
        due_date = Kronic.parse(ef)

        $assignment.due_date = due_date
        message = "Your assignment is for #{$assignment['course_name']}: #{assignment['description']} due #{assignment['due_date']}"
        client.chat_postMessage(channel: event.channel, text: message, attachments: interactive_confirmation_assignment ,as_user: true)

      elsif ef.starts_with? "course name: "

        ef.slice!(0..12)
        $course_object["course_name"]= ef
        client.chat_postMessage(channel: event.channel, text: "Enter Course ID starting with *course id: *", as_user: true)

      elsif ef.starts_with? "course id: "

        ef.slice!(0..10)
        $course_object["course_id"]= ef  
        client.chat_postMessage(channel: event.channel, text: "Enter Instructor Name starting with *instructor: *", as_user: true) 

      elsif ef.starts_with? "instructor: "

        ef.slice!(0..11)
        $course_object["instructor"]= ef

        client.chat_postMessage(channel: event.channel, text: "You've entered the following: #{$course_object["course_name"]}, #{$course_object["course_id"]}, by #{$course_object["instructor"]}", attachments: interactive_confirmation_course, as_user: true)

      elsif event.formatted_text == "show assignments"

        client.chat_postMessage(channel: event.channel, text: get_upcoming_assignments, as_user: true)

      elsif event.formatted_text == "show courses"

        client.chat_postMessage(channel: event.channel, text: show_courses, as_user: true)

      elsif second_last_event["direction"] == "outgoing" && second_last_event["text"] == "add assignment description"

          $assignment.description = input
          client.chat_postMessage(channel: second_last_event.channel, text: "So when is this assignment due?", as_user: true)
          add_outgoing_event team, "message", "add assignment due-date"

      elsif second_last_event["direction"] == "outgoing" && second_last_event["text"] == "add assignment due-date"
          
          due_date = Kronic.parse(input)

          $assignment.due_date = due_date
          message = "Your assignment is for #{$assignment['course_name']}: #{assignment['description']} due #{input}, #{assignment['due_date']}."
          client.chat_postMessage(channel: second_last_event.channel, text: message, attachments: interactive_confirmation_assignment, as_user: true)
      
      else

          manage_errors event, client

      end      
    end
    
    #METHOD: Converts the list of commands to a message
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

    #METHOD: Gets useful user information from Slack
    def get_user_name client, event
      # calls users_info on slack
      info = client.users_info(user: event.user_id )
      info['user']['name']
    end
    
    #METHOD: Returns if the client is an admin or not
    def is_admin_or_owner client, event
      # calls users_info on slack
      info = client.users_info(user: event.user_id ) 
      info['user']['is_admin'] || info['user']['is_owner']
    end

    #METHOD: Returns the about me message for Jude
    def about_jude
      message = "Jude was created one dark fall morning by a bright young student in Mandark's Lab in Pittsburgh. \nWhile he realised that his assignments were going out of hand he decided to build something that would solve his problem and others. \nJude has been built to make it easier to add structure to google calendar events for assignments, as well as show upcoming events." 
      return message
    end

    #METHOD: Managing the error messages
    def manage_errors event, client

      puts "Error Counter #{ @@error_counter }"
        
      @@error_counter += 1

      if @@error_counter > 5
        client.chat_postMessage(channel: event.channel, text: "This is really fishy now. Why are you doing this? :unamused: Please be nice or type `help` to find my commands.", as_user: true)
      elsif @@error_counter > 2 and @@error_counter <= 4
        client.chat_postMessage(channel: event.channel, text: "Hmmm, you seem to be different today :thinking_face:. Hope all is well. Anyways, type `help` to find my commands.", as_user: true)  
      else
        client.chat_postMessage(channel: event.channel, text: "I didn't get that but that's alright. If you're stuck, type `help` to find my commands.", as_user: true)
      end
    end

    #METHOD: Managing adding assignment flow
    # def assignment_flow input, team

    #   user_events = Event.find_by(user_id: team['user_id'])
    #   second_last_event = user_events[-2]

    #   if second_last_event["direction"] == "outgoing" && second_last_event["text"] == "add assignment description"

    #     $assignment.description = input
    #     client.chat_postMessage(channel: second_last_event.channel, text: "So when is this assignment due?", as_user: true)
    #     add_outgoing_event team, "message", "add assignment due-date"
  

    #   elsif second_last_event["direction"] == "outgoing" && second_last_event["text"] == "add assignment due-date"
          
    #     due_date = Kronic.parse(input)

    #     $assignment.due_date = due_date
    #     message = "Your assignment is for #{$assignment['course_name']}: #{assignment['description']} due #{input}, #{assignment['due_date']}."
    #     client.chat_postMessage(channel: second_last_event.channel, text: message, attachments: interactive_confirmation_assignment, as_user: true)
  

    #   else
    #     200
    #   end

    # end

    def add_outgoing_event team , type , text
      #Resetting error counter
      @@error_counter = 0

      event = Event.create(team_id: team["team_id"], user_id: team["user_id"], type_name: type, text: text, channel: team["channel"], direction: "outgoing", timestamp: Time.now)
      event.team = team
      event.save!

    end

  end
  
end