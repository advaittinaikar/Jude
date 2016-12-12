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

        # intialize_api
        message = interactive_greeting
        client.chat_postMessage(channel: event.channel, text: "Hello there. Let's get something done today.", attachments: message, as_user:true)

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

        $assignment_object[:due_date] = due_date
        
        add_assignment_to_table $assignment_object

        client.chat_postMessage(channel: event.channel, text: "So your assignment is #{$assignment_record}, due #{ef} ( #{due_date} )", as_user: true)

        # message create_calendar_event $assignment_object, $service  
        # client.chat_postMessage(channel: event.channel, text: message, as_user: true)

      elsif ef.starts_with? "course name: "
        ef.slice!(0..12)
        $course_object[:course_name]= ef  
        client.chat_postMessage(channel: event.channel, text: "Enter Course ID starting with ~course id: ~", as_user: true)

      elsif ef.starts_with? "course id: "
        ef.slice!(0..10)
        $course_object[:course_id]=ef  
        client.chat_postMessage(channel: event.channel, text: "Enter Instructor Name starting with ~instructor: ~", as_user: true) 

      elsif ef.starts_with? "instructor: "
        ef.slice!(0..11)  
        $course_object[:instructor]= ef 
        client.chat_postMessage(channel: event.channel, text: "Enter Abbreviation of the course name starting with ~short name: ~", as_user: true)  

      elsif ef.starts_with? "short name: "
        ef.slice!(0..11)  
        $course_object[:short_name]= ef
        create_course $course_object 
        client.chat_postMessage(channel: event.channel, text: "You've entered the following: #{$course_object["course_name"]} \n #{$course_object["course_id"]} \n #{$course_object["instructor"]} \n #{$course_object["short_name"]} \n", as_user: true)

        $assignment_record=""

        # message = "Let's add an assignment!"
        # puts 'replace message'
        # client.chat_postMessage(channel: channel, text: message, attachments: interactive_assignment_course, as_user: true)

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
          client.chat_postMessage(channel: event.channel, text: "Hmmm, you seem to be different today. Hope all is well. Anyways, type `help` to find my commands.", as_user: true)  
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

    def create_course object

      course = Course.create(course_name: object.course_name, course_id: object.course_id, instructor: object.instructor, short_name: object.short_name)
      course.save

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
      actions_response = [
        {
          "text": "Which course is the assignment for?",
          "callback_id": "course_assignment",
          "fallback": "Type your course number",
          "actions": [
            { 
              "name": "add course",
              "text": "+ Add a course",
              "type": "button"
            }
          ]

        }
      ]

      #Adding course details from the database
      Course.all.each do |item,index|


        actions_response.first[:actions].insert(0,
        {
          "name": item[:short_name],
          "text": item[:course_name],
          "type": "button"
          }
        )

      end

      return actions_response.to_json

    end

    def add_assignment_to_table object

      assignment = Assignment.create(course_name: object["course_name"], description: object["description"], due_date: object["due_date"])
      assignment.save

    end

  end
  
end