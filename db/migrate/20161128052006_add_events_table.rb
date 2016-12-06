class AddEventsTable < ActiveRecord::Migration[5.0]
  def change
    
    
    create_table :events do |t|

      t.string    :team_id
      t.string    :type_name
      t.string    :user_id
      t.text      :text
      t.string    :channel
      t.datetime  :timestamp

    end
    
    
  end
end
