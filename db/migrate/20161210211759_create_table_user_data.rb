class CreateTableUserData < ActiveRecord::Migration[5.0]
  def change

  	create_table :users do |t|

      t.string    :user_name
      t.string    :user_id
      t.string    :courses_taken
      t.string	  :team_name
      t.string	  :team_id
      t.timestamps

    end

  end
end
