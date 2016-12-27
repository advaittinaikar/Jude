require 'sinatra'

class Assignment < ActiveRecord::Base
  
  #has_many :tasks, dependent: :destroy
  has_many :courses
    
  validates_presence_of :course_name
  validates_presence_of :description
  validates_presence_of :due_date    

end