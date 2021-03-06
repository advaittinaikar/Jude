module Sinatra
	module DatabaseHelper

		#METHOD: Adds a course to the course table
		def create_course object
		  course_name = object['course_name'].capitalize
	   	  course_id = object['course_id']
	      short_name = abbreviate course_name
	      instructor =  object['instructor'].capitalize

	      course = Course.create(:course_name => course_name, :course_id => course_id, :instructor => instructor, :short_name => short_name)
	      course.save!
	    end

	    #METHOD: Adds an assignment to the assignment table
	    def create_assignment(object,client,channel)
	    	course_name = object['course_name']
	    	description = object['description']
	    	due_date = object['due_date']

		    assignment = Assignment.create!(:course_name => course_name, :description => description, :due_date => due_date)
		    assignment.save!

		    return "Assignment for #{course} regarding #{description}, due #{due_date} has been created!"
    	end

    	def show_assignments
    		message=""

    		Assignment.all.each do |assignment|
    			message+="#{assignment["course_name"]}, #{assignment["description"]}, #{assignment["due_date"]}\n"
    		end

    		return message
    	end

		def show_courses
    		message=""

    		Course.all.each do |course|
    			message+="#{course["course_name"]}, #{course["course_id"]}, #{course["instructor"]}\n"
    		end

    		return message
    	end	

    	def abbreviate name
    		words = name.split(" ")
    		short_name = ""

    		words.each do |word|
    			short_name += word.slice(0)
    		end

    		return short_name.upcase
    	end

	end
end