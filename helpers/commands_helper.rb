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
    
    def event_to_action client, event
      
      ef = event.formatted_text
      puts "Formatted Text: #{event.formatted_text}"
      
      return if ef.nil?
      
      is_admin = is_admin_or_owner client, event

      # if session[:access_token].nil?
      #     auth_calendar
      # end
        
      # Hi Commands
      if ["hi","hello","hey","heyy"].any? { |w| ef.starts_with? w }

        message = interactive_greeting
        client.chat_postMessage(channel: event.channel, text: "Hello there. I'm Jude. Let's get something done for you today.", attachments: message, as_user:true)

      elsif ef.starts_with? "about"
        client.chat_postMessage(channel: event.channel, text: "_#{about_jude}_", attachments: message, as_user:true)
            
      # Handle the Help commands
      elsif ef.include? "help"
        client.chat_postMessage(channel: event.channel, text: get_commands_message( is_admin ), as_user: true)

      # Respond to thanks message
      elsif ef.starts_with? "thank"
        client.chat_postMessage(channel: event.channel, text: "That's mighty nice of you. You're welcome and thank you for having me!", as_user: true)

      #   
      elsif ef.starts_with? "details:"
        ef.slice!(0..8)
        $assignment_record += " " + ef
        $assignment_object["description"] = ef
        puts $assignment_record
        client.chat_postMessage(channel: event.channel, text: "So when is this assignment due?", as_user: true)

      elsif ef.starts_with? "due:"
        ef.slice!(0..4)
        due_date = Kronic.parse(ef)

        $assignment_object["due_date"] = due_date
        
        puts $assignment_object

        add_assignment_to_table($assignment_object,client,event.channel)

        client.chat_postMessage(channel: event.channel, text: "So your assignment is #{$assignment_record}, due #{ef} ( #{due_date} )", as_user: true)

        # message create_calendar_event $assignment_object, $service  
        # client.chat_postMessage(channel: event.channel, text: message, as_user: true)

      elsif ef.starts_with? "course name: "
        ef.slice!(0..12)
        $course_object[:course_name]= ef
        client.chat_postMessage(channel: event.channel, text: "Enter Course ID starting with ~course id: ~", as_user: true)

      elsif ef.starts_with? "course id: "
        ef.slice!(0..10)
        $course_object[:course_id]= ef  
        client.chat_postMessage(channel: event.channel, text: "Enter Instructor Name starting with ~instructor: ~", as_user: true) 

      elsif ef.starts_with? "instructor: "
        ef.slice!(0..11)  
        $course_object[:instructor]= ef
        client.chat_postMessage(channel: event.channel, text: "Enter Abbreviation of the course name starting with ~short name: ~", as_user: true)  

      elsif ef.starts_with? "short name: "
        ef.slice!(0..11)  
        $course_object[:short_name]= ef

        client.chat_postMessage(channel: event.channel, text: "You've entered the following: user research methods, 49-712, by francine gemperle", as_user: true)

        # create_course $course_object 
        
        $assignment_record = ""

        # message = "Let's add an assignment!"
        # puts 'replace message'
        # client.chat_postMessage(channel: channel, text: message, attachments: interactive_assignment_course, as_user: true)

      elsif event.formatted_text == "show assignments"

        client.chat_postMessage(channel: event.channel, text: show_assignments, as_user: true)

      elsif event.formatted_text == "add"
        $assignment_record = ""

        add_event client, event.channel

      else

        # ERROR Commands
        # not understood or an error
        puts "Error Counter #{ @@error_counter }"
        
        @@error_counter += 1

        if @@error_counter > 5
          client.chat_postMessage(channel: event.channel, text: "This is really fishy now. You've entered something I dont get for the #{@@error_counter}th time. Please be nice or type `help` to find my commands.", as_user: true)
        elsif @@error_counter > 2 and @@error_counter <= 4
          client.chat_postMessage(channel: event.channel, text: "Hmmm, you seem to be different today. Hope all is well. Anyways, type `help` to find my commands.", as_user: true)  
        else  
          client.chat_postMessage(channel: event.channel, text: "I didn't get that but that's alright. If you're stuck, type `help` to find my commands.", as_user: true)
        end
        
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
      message = "_Jude was created one dark fall morning by a bright young student in Mandark's Lab in Pittsburgh. \nWhile he realised that his assignments were going out of hand he decided to build something that would solve his problem and others. \nJude has been built to make it easier to add structure to google calendar events for assignments, as well as show upcoming events._" 
      return message
    end

  end
  
end