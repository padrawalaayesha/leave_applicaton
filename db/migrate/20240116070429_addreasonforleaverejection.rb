class Addreasonforleaverejection < ActiveRecord::Migration[6.0]
  def change
    add_column :holidays, :rejection_reason, :text
  end
end
