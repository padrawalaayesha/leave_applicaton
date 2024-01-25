class AddApprovalStatusToEmployee < ActiveRecord::Migration[6.0]
  def change
    add_column :employees, :approval_status, :string, default: 'pending'
  end
end
