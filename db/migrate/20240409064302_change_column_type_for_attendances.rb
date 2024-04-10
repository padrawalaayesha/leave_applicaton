class ChangeColumnTypeForAttendances < ActiveRecord::Migration[6.0]
  def change
    change_column :attendances, :checkin_location, :jsonb
    change_column :attendances, :checkout_location, :jsonb
  end
end
