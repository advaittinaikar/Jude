class Team < ActiveRecord::Base
  
  #has_many :tasks, dependent: :destroy
  
  validates_presence_of :team_id
  validates_presence_of :user_id
  validates_presence_of :calendar_token
  validates_presence_of :calendar_Code
  
  has_many :events
  
  
  def get_client
    
    Slack.configure do |config|
      config.token = self.bot_token
    end
    
    client = Slack::Web::Client.new
    
  end
  
end