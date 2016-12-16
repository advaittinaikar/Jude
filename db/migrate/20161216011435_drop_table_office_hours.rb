class DropTableOfficeHours < ActiveRecord::Migration[5.0]
  def change

  	drop_table :office_hours_queues

  end
end
