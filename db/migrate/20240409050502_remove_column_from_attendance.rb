class RemoveColumnFromAttendance < ActiveRecord::Migration[6.0]
  def change
    remove_column :attendances, :location
  end
end
