require 'active_support/all'

Course.delete_all

Course.create!([{ course_name: "Design for the Environment", course_id: "49-100", short_name: "DFE", instructor: "Steve Leonard" },
				{ course_name: "Programming for Online Prototypes", course_id: "49-101", short_name: "POP", instructor: "Daragh Bryne"},
				{ course_name: "Visual Processes", course_id: "49-102", short_name: "VP", instructor: "Eric Anderson"} ])