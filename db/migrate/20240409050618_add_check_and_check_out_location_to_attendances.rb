class AddCheckAndCheckOutLocationToAttendances < ActiveRecord::Migration[6.0]
  def change
    add_column :attendances, :checkin_location, :text
    add_column :attendances, :checkout_location, :text
  end
end
