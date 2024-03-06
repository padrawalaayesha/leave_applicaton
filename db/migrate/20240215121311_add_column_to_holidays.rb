class AddColumnToHolidays < ActiveRecord::Migration[6.0]
  def change
    add_column :holidays, :number_of_days, :integer
  end
end
