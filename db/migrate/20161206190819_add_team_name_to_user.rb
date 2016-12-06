class AddTeamNameToUser < ActiveRecord::Migration[5.0]
  def change
  	add_column :users, :team_name, :string

    add_column :users, :team_id, :string
  end
end
