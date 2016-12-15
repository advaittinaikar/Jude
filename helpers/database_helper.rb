module Sinatra
	module DatabaseHelper

		#METHOD: Adds a course to the course table
		def create_course object
	      course = Course.create(:course_name => object["course_name"], :course_id => object["course_id"], :instructor => object["instructor"], :short_name => object["short_name"])
	      course.save
	      puts "Course created succesfully!"
	    end

	    #METHOD: Adds an assignment to the assignment table
	    def add_assignment_to_table(object,client,channel)
	    	course_name = object['course_name']
	    	description = object['description']
	    	due_date = object['due_date']

		    assignment = Assignment.create(:course_name => course_name, :description => description, :due_date => due_date)
		    assignment.save

		    client.chat_postMessage(channel: channel,text: "Assignment with #{course_name}, #{description}, #{due_date} has been saved to db" ,as_user: true)
		    puts "Assignment saved!"
    	end

    	def show_assignments
    		message=""

    		Assignment.all.each do |assignment|
    			message+="#{assignment["course_name"]}, #{assignment["description"]}, #{assignment["due_date"]}\n"
    		end

    		return message
    	end
	end
end