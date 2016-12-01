class AddLegendColumnToDatasets < ActiveRecord::Migration[5.0]
  def change
    add_column :datasets, :legend, :jsonb, default: {}
    add_index :datasets,  :legend, using: :gin
  end
end
