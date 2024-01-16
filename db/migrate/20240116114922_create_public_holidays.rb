class CreatePublicHolidays < ActiveRecord::Migration[6.0]
  def change
    create_table :public_holidays do |t|
      
      t.date :date
      t.string :name

      t.timestamps
    end
  end
end
