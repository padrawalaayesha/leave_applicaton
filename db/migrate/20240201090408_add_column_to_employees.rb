class AddColumnToEmployees < ActiveRecord::Migration[6.0]
  def change
    add_column :employees, :reset_code, :string
  end
end
