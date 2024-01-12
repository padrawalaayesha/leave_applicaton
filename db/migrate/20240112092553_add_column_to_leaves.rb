class AddColumnToLeaves < ActiveRecord::Migration[6.0]
  def change
    add_column :leaves, :leave_type, :string
  end
end
