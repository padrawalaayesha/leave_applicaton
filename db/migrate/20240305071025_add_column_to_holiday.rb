class AddColumnToHoliday < ActiveRecord::Migration[6.0]
  def change
    add_column :holidays, :sandwich_weekend, :boolean, default: false
  end
end
