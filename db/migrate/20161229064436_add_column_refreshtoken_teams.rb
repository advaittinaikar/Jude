class AddColumnRefreshtokenTeams < ActiveRecord::Migration[5.0]
  def change

  	add_column :teams, :calendar_refresh_token, :string

  end
end
