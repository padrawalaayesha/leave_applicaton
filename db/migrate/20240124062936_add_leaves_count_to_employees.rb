class AddLeavesCountToEmployees < ActiveRecord::Migration[6.0]
  def change
    add_column :employees, :casual_leave_count, :integer
    add_column :employees, :sick_leave_count, :integer
    add_column :employees, :work_from_home_count, :integer
    add_column :employees, :leave_without_pay_count, :integer
  end
end
