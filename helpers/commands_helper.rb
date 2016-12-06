module Sinatra
  module CommandsHelper
  
    # ------------------------------------------------------------------------
    # =>   A LIST OF ACTIONS
    # ------------------------------------------------------------------------

    @@course_bot_commands = [
      { message: "*queue status* - Shows the current queue for office hours", is_admin: false },
      { message: "*queue me [message]* - Adds you to the queue for office hours. _Optional_ Include a message with what help you're looking for", is_admin: false },
      { message: "*queue remove* - Removes you from the queue for office hours", is_admin: false },
      { message: "*queue status* - Gets the list of who's next in the ofifce hour queue", is_admin: false },
      { message: "*queue next* - Plucks the next person from the office hours queue and lets them know you're ready for them", is_admin: true },
      { message: "*queue clear* - Trashes the office hours queue", is_admin: true },
      { message: "*help* - Shows help information", is_admin: false },
      { message: "*hi* - Say hello", is_admin: false }
    ]
    
    # ------------------------------------------------------------------------
    # =>   MAPS THE CURRENT EVENT TO AN ACTION
    # ------------------------------------------------------------------------
    
    def event_to_action client, event
      
      puts event
      puts "Formatted Text: #{event.formatted_text}"
      
      return if event.formatted_text.nil?
      
      is_admin = is_admin_or_owner client, event
        
      # Hi Commands
      if ["hi", "hey", "hello"].any? { |w| event.formatted_text.starts_with? w }
        client.chat_postMessage(channel: event.channel, text: "Hi I'm CourseBot. I'm here to help.", as_user: true)

        # Handle the Help commands
      elsif event.formatted_text.include? "help"
        client.chat_postMessage(channel: event.channel, text: get_commands_message( is_admin ), as_user: true)

      elsif event.formatted_text.starts_with? "thank"
        client.chat_postMessage(channel: event.channel, text: "You're very welcome.", as_user: true)

      elsif event.formatted_text.starts_with? "queue me" or event.formatted_text.starts_with? "q me"
        add_user_to_office_hours_queue client, event
      elsif event.formatted_text.starts_with? "queue add" or event.formatted_text.starts_with? "q add"
        add_user_to_office_hours_queue client, event
        
      elsif event.formatted_text.starts_with? "queue remove" or event.formatted_text.starts_with? "q remove"
        remove_user_from_office_hours_queue client, event

      elsif event.formatted_text.starts_with? "queue status" or event.formatted_text.starts_with? "q status"
        get_office_hours_queue_status client, event

      elsif event.formatted_text.starts_with? "queue status" or event.formatted_text.starts_with? "q status"
        get_office_hours_queue_status client, event

      elsif is_admin and (event.formatted_text.starts_with? "queue next" or event.formatted_text.starts_with? "q next")
        office_hours_next_in_queue client, event
        
      elsif is_admin and (event.formatted_text.starts_with? "queue clear" or event.formatted_text.starts_with? "q clear")
        office_hours_clear_queue client, event
                             
      else
        # ERROR Commands
        # not understood or an error
        client.chat_postMessage(channel: event.channel, text: "I didn't get that. If you're stuck, type `help` to find my commands.", as_user: true)
        
      end
      
    end
    
    # ------------------------------------------------------------------------
    # =>   CONVERTS THE LIST OF COMMANDS TO A FORMATTED MESSAGE
    # ------------------------------------------------------------------------
    
    def get_commands_message is_admin = false
      
        message = "*CourseBot* - This bot helps you manage this course\n"
        message += "*Commands:* \n"
      
        @@course_bot_commands.each do |c|
          if c[:is_admin] == false or (c[:is_admin] == true and is_admin)
            message += c[:message] + "\n"
          end
        end

        message

    end


    # ------------------------------------------------------------------------
    # =>   GETS USEFUL INFO FROM SLACK
    # ------------------------------------------------------------------------
    
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
  
  end
  
end