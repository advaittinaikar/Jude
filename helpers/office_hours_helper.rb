module Sinatra
  module OfficeHoursHelper
  
    # This function adds a user to the office hours queue
    def add_user_to_office_hours_queue client, event
  
      # 1. check to see if the user is in the queue
      current_queue = OfficeHoursQueue.where( team_id: event.team_id ) 
      user_in_queue = current_queue.where(  user_id: event.user_id )
      
      
      if user_in_queue.empty?

        # 2. If they are then add them and let them know
        description = event.text.gsub( "q me", "" ).gsub( "queue me","" )
        description = description.strip! unless description.blank?
        
        item = OfficeHoursQueue.create( team_id: event.team_id, user_id: event.user_id, message: description )
        item.user_name = get_user_name( client, event )
        item.save
        
        message = "You've been added to the office hours queue. "
        message += "You're #{ (current_queue.length).ordinalize } in line."
        
        client.chat_postMessage(channel: event.channel, text: message, as_user: true)
        
      else 
        # 3. Otherwise tell them they're in the queue and how many people left.
        position_in_queue = current_queue.map(&:user_id).index(event.user_id)
        
        message = "You're already in the queue. "
        message += "You're #{ (position_in_queue+1).ordinalize } in line."
        
        client.chat_postMessage(channel: event.channel, text: message, as_user: true)
          
      end
  
    end
    
    
    def remove_user_from_office_hours_queue client, event
    
      # 1. check to see if the user is in the queue
      current_queue = OfficeHoursQueue.where( team_id: event.team_id ) 
      user_in_queue = current_queue.where(  user_id: event.user_id )
      
      
      if user_in_queue.empty?
        # 3. They're not in it.
        message = "You're not in the queue. Type `queue me` to add."
        client.chat_postMessage(channel: event.channel, text: message, as_user: true)
      else 
        user_in_queue.destroy_all
        message = "You've been removed from the  office hours queue. Type `queue status` to see who's in it."
        client.chat_postMessage(channel: event.channel, text: message, as_user: true)
        
      end 
    
    end
    
    
    def get_office_hours_queue_status client, event
    
      current_queue = OfficeHoursQueue.where( team_id: event.team_id ) 
    
      if current_queue.empty?
        message = "There's no one in the queue. Type `queue me` to add."
        client.chat_postMessage(channel: event.channel, text: message, as_user: true)
      else
        message = "There's #{ current_queue.length } people in the queue:"
        attachments = []
        current_queue.each_with_index do |q, index|
          attachments << get_queue_attachment_for( q )
        end
        client.chat_postMessage(channel: event.channel, text: message, attachments: attachments.to_json , as_user: true)
      end
    end
      
    # removes the first person from the queue 
    # and sends a message to alert them that it is their turn. 
    # It also displays the new status of the queue.
    def office_hours_next_in_queue client, event
      
      current_queue = OfficeHoursQueue.where( team_id: event.team_id ) 
      
      if current_queue.empty?
        message = "Congrats! The queue is empty! "
        client.chat_postMessage(channel: event.channel, text: message, as_user: true)
      else
        # get the next in line
        next_up = current_queue.first

        # send them a private message...
        
        # notify the admin
        attachments = []
        attachments << get_queue_attachment_for( next_up )
        
        message = "Next in the queue:"
        client.chat_postMessage(channel: event.channel, text: message, attachments: attachments.to_json , as_user: true)

        admin_user = get_user_name( client, event )

        client.chat_postMessage(channel: "@#{next_up.user_name}", text: "You've made it to the top of the queue! @#{ admin_user } will see you now.", attachments: attachments.to_json , as_user: true)
        
        # finally remove them from the queue 
        current_queue.destroy
        
      end 
      
    end
    
    # removes the first person from the queue 
    # and sends a message to alert them that it is their turn. 
    # It also displays the new status of the queue.
    def office_hours_clear_queue client, event
      
      current_queue = OfficeHoursQueue.where( team_id: event.team_id ) 
      
      if current_queue.empty?
        message = "Congrats! The queue is already empty! "
        client.chat_postMessage(channel: event.channel, text: message, as_user: true)
      else
        
        # finally remove them from the queue 
        current_queue.destroy_all
        message = "The queue is trashed! "
        client.chat_postMessage(channel: event.channel, text: message, as_user: true)
        
      end 
      
    end
      
    def get_queue_attachment_for queue
      since_str = minutes_in_words queue.created_at # formatted in words 
      { author: "Daragh Byrne", author_link: "http://daragbyrne.me", 
        title: "@#{queue.user_name} - waiting #{since_str}", text: "*Topic:* #{queue.message.blank? ? "_Unspecified_" : queue.message }", mrkdwn_in: [ "text" ] }
    end
      
  end
  
end