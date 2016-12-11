class AddShortNameToCoursesTable < ActiveRecord::Migration[5.0]
  def change

  	add_column :courses, :short_name, :string
  	add_column :courses, :instructor, :string

  end
end
