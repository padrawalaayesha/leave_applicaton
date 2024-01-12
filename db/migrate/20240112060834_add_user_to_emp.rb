class AddUserToEmp < ActiveRecord::Migration[6.0]
  def change
    add_column :employees, :user_id , :int
  end
end
