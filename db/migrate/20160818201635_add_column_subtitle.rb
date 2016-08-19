class AddColumnSubtitle < ActiveRecord::Migration[5.0]
  def change
    add_column :datasets, :subtitle, :string
  end
end
