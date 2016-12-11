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
      
      puts event
      puts "Formatted Text: #{event.formatted_text}"
      
      return if event.formatted_text.nil?
      
      is_admin = is_admin_or_owner client, event
        
      # Hi Commands
      if ["hi", "hey", "hello"].any? { |w| event.formatted_text.starts_with? w }
        client.chat_postMessage(channel: event.channel, text: "Hi I'm Jude. I was created to help you with your assignments. What do you want to add today?", as_user: true)

        # Handle the Help commands
      elsif event.formatted_text.include? "help"
        client.chat_postMessage(channel: event.channel, text: get_commands_message( is_admin ), as_user: true)

      elsif event.formatted_text.starts_with? "thank"
        client.chat_postMessage(channel: event.channel, text: "That's mighty nice of you. You're welcome and thank you for having me!", as_user: true)
      
      elsif event.formatted_text == "show"
        events_message = get_upcoming_events calendar_service
        client.chat_postMessage(channel: event.channel, text: events_message, as_user: true)

      elsif event.formatted_text == "add"
        client.chat_postMessage(channel: event.channel, text:"Add to your calendar", attachments:message_add_event)

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
    
    # ------------------------------------------------------------------------
    # =>   CONVERTS THE LIST OF COMMANDS TO A FORMATTED MESSAGE
    # ------------------------------------------------------------------------
    
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

    def message_add_event
      
      {
    "attachments": [
        {
            "text": "What would you like to add?",
            "fallback": "Sorry could not add that.",
            "callback_id": "wopr_game",
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
        ]
      }.to_json
    
    end
  
  end
  
end