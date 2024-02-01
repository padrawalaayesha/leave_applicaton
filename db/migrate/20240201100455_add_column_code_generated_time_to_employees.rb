class AddColumnCodeGeneratedTimeToEmployees < ActiveRecord::Migration[6.0]
  def change
    add_column :employees, :code_generated_time, :datetime
  end
end
