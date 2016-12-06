class AddTeamsTable < ActiveRecord::Migration[5.0]
  def change
    
    create_table :teams do |t|

      t.string    :access_token
      t.string    :team_name
      t.string    :team_id
      t.string    :user_id
      t.text      :raw_json
      t.string    :incoming_webhook
      t.string    :incoming_channel
      t.string    :bot_token
      t.string    :bot_user_id
      t.boolean   :is_active, default: true

    end
    
  end
end

