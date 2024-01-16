class AddApprovedHolidays < ActiveRecord::Migration[6.0]
  def change
    add_column :holidays, :approval_status , :boolean, default: false
  end
end
