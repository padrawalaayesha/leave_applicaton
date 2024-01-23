class AddColumnsToEmployees < ActiveRecord::Migration[6.0]
  def change
    add_column :employees, :department, :integer
    add_column :employees, :designation, :string
    add_column :employees, :date_of_joining, :date
    add_column :employees, :birth_date, :date
    add_column :employees, :education, :string
    add_column :employees, :passing_year, :string

  end
end
