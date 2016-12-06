class OfficeHoursQueue < ActiveRecord::Base
  
  #has_many :tasks, dependent: :destroy
  
  belongs_to :team
  
  validates_presence_of :team_id

  
end