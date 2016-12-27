class AddColumnGooglecodeTeams < ActiveRecord::Migration[5.0]
  def change
  	add_column :teams, :calendar_code, :string
  end
end
