module Sinatra
	module DatabaseHelper

		#METHOD: Adds a course to the course table
		def create_course object
	      course = Course.create(course_name: object["course_name"], course_id: object["course_id"], instructor: object["instructor"], short_name: object["short_name"])
	      course.save
	    end

	    #METHOD: Adds an assignment to the assignment table
	    def add_assignment_to_table object
	      assignment = Assignment.create(course_name: object["course_name"], description: object["description"], due_date: object["due_date"])
	      assignment.save
    	end

	end
end