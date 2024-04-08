class CreateAttendances < ActiveRecord::Migration[6.0]
  def change
    create_table :attendances do |t|
      t.date :date
      t.time :checkin_time
      t.time :checkout_time
      t.string :location
      t.references :employee, null: false, foreign_key: true

      t.timestamps
    end
  end
end
