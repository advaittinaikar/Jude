class AddIocolumnEvents < ActiveRecord::Migration[5.0]
  def change

  	add_column :events, :direction, :string

  end
end
