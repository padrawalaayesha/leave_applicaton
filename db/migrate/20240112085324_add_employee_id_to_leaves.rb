class AddEmployeeIdToLeaves < ActiveRecord::Migration[6.0]
  def change
    add_column :leaves, :employee_id, :int
  end
end
