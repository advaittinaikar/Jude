class AddColumnDetailsAssignments < ActiveRecord::Migration[5.0]
  def change

  	add_column :assignments, :user_id, :string
  	add_column :assignments, :team_id, :string
  	add_column :assignments, :hours_required, :integer
  	add_column :assignments, :reminder_days, :integer

  end
end
