module Sinatra
	module SlackInteractionsHelper

		#METHOD: Posts message in a slakc DM or Channel
		# def post_message(client, channel, text, attachment)
		# 	client.chat_postmessage (channel: channel, text: text, attachment: attachment, as_user: true)
		# end

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

	      puts Course.all.to_json

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

	    def interactive_confirmation_assignment
	    	[
	    		{
	    			"text": "Can I add it your Calendar?",
	    			"callback_id": "confirm_assignment",
	    			"fallback": "Add assignment to Calendar?",
	    			"actions":[
					{
					"name": "confirm",
					"text": "Confirm?",
					"type": "button"    				
				    			},
				    {
					"name": "change",
					"text": "Change",
					"type": "button"    				
				    			}
		    		]

	    			}
			].to_json
	    end

	    def interactive_confirmation_course
	    	[
	    		{
	    			"text": "Can I add this course to your list of courses?",
	    			"callback_id": "confirm_course",
	    			"fallback": "Add course to Calendar?",
	    			"actions":[
					{
					"name": "confirm",
					"text": "Confirm?",
					"type": "button"    				
				    			},
				    {
					"name": "change",
					"text": "Change",
					"type": "button"    				
				    			}
		    		]

	    			}
			].to_json
	    end

	    def add_event client, channel

	    	attachment = [
	        {
	          # "text": "What would you like to add?",
	          "fallback": "You're missing out on a great experience!",
	          "callback_id": "add event",
	          "attachment_type": "default",
	          "actions": [
	            {
	              "name":  "add assignment",
	              "text":  "Add Assignment",
	              "type":  "button"
	              },
	            {
	              "name":  "add course",
	              "text":  "Add Course",
	              "type":  "button"
	              } 
	          	]	
	        	}
	      	].to_json

	    	client.chat_postMessage(channel: channel, text: "What would you like to add?", attachments: attachment, as_user: true)

	    end
	end
end