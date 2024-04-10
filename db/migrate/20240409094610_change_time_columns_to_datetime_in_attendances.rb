class ChangeTimeColumnsToDatetimeInAttendances < ActiveRecord::Migration[6.0]
  def change
    change_column :attendances, :checkin_time, :datetime
    change_column :attendances, :checkout_time, :datetime
  end
end
