require 'sinatra'

class Event < ActiveRecord::Base
  
  #has_many :tasks, dependent: :destroy
  belongs_to :team
    
  validates_presence_of :team_id

  def formatted_text
    text.to_s.downcase.strip
  end

  
end