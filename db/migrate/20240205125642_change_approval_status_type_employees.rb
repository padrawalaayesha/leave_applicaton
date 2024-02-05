class ChangeApprovalStatusTypeEmployees < ActiveRecord::Migration[6.0]
  def change
    change_column :employees, :approval_status, :integer, default: 0
  end
end
