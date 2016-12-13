module Sinatra
	module SlackInteractionsHelper

		#METHOD: Posts message in a slakc DM or Channel
		def post_message(client, channel, text, attachment)
			client.chat_postmessage (channel: channel,text: text, attachment: attachment, as_user: true)
		end

		#METHOD: Interactive message body when user says hi
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

	    #METHOD: Interactive message body when user wants to add the course of an assignment
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


	        actions_response.first[:actions].push(
	        {
	          "name": item[:short_name],
	          "text": item[:course_name],
	          "type": "button"
	          }
	        )

	      end

	      return actions_response.to_json

	    end
	end
end