class RemoveColumnFromLeave < ActiveRecord::Migration[6.0]
  def change
    remove_column :leaves, :type, :string
  end
end
