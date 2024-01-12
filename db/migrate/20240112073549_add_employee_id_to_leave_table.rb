class AddEmployeeIdToLeaveTable < ActiveRecord::Migration[6.0]
  def change
    add_column :leaves, :emp_id , :int
  end
end
