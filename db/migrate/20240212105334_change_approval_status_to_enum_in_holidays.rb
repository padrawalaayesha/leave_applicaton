class ChangeApprovalStatusToEnumInHolidays < ActiveRecord::Migration[6.0]
  def change
    change_column :holidays, :approval_status, :integer, default: 0
  end
end
