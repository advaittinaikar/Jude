class CreateTableAssignments < ActiveRecord::Migration[5.0]
  def change

  	create_table :assignments do |t|

      t.string    :course_name
      t.string    :description
      t.datetime  :due_date
      t.timestamps

    end

  end
end
