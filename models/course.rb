class Assignment < ActiveRecord::Base
  
  #has_many :tasks, dependent: :destroy
  belongs_to :team
    
  validates_presence_of :course_name
  validates_presence_of :course_id

  def formatted_text
    text.downcase.strip
  end    
  
end