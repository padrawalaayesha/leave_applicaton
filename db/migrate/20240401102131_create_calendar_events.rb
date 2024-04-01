class CreateCalendarEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :calendar_events do |t|

      t.string :title
      t.text :description
      t.datetime :start_date
      t.datetime :end_date
      t.string :color
      t.references :employee, foreign_key: true

      t.timestamps
    end
  end
end
