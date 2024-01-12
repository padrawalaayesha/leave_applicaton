class CreateHolidaysTable < ActiveRecord::Migration[6.0]
  def change
    create_table :holidays do |t|
      t.string :h_type
      t.text   :description
      t.date   :start_date
      t.date   :end_date
      t.integer :employee_id


      t.timestamps
    end
  end
end
