class Assignment < ActiveRecord::Base
  
  #has_many :tasks, dependent: :destroy
  belongs_to :team
    
  validates_presence_of :user_id
  validates_presence_of :user_name
  validates_presence_of :courses_taken

  def formatted_text
    text.downcase.strip
  end    

end