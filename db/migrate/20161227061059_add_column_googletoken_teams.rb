class AddColumnGoogletokenTeams < ActiveRecord::Migration[5.0]
  def change

  	add_column :teams, :calendar_token, :string
  	
  end
end
