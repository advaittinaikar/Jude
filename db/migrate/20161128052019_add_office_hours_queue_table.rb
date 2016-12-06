class AddOfficeHoursQueueTable < ActiveRecord::Migration[5.0]
  def change
    
    create_table :office_hours_queues do |t|

      t.string    :team_id
      t.string    :user_id
      t.string    :user_name
      t.text      :message
      t.timestamps
    end
    
  end
end
