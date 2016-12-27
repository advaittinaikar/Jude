require 'sinatra'

class Course < ActiveRecord::Base
  
  #has_many :tasks, dependent: :destroy
  #belongs_to :team
    
  validates_presence_of :course_name
  validates_presence_of :course_id

  def abbreviate
    words = course_name.split(" ")
	short_name = ""

	words.each do |word|
		short_name += word.slice(0)
	end
  end
  
end