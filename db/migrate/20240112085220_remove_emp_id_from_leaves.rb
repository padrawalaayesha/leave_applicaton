class RemoveEmpIdFromLeaves < ActiveRecord::Migration[6.0]
  def change
    remove_column :leaves, :emp_id, :integer
  end
end
