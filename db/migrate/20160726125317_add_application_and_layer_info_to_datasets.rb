class AddApplicationAndLayerInfoToDatasets < ActiveRecord::Migration[5.0]
  def change
    add_column :datasets, :application, :jsonb, default: []
    add_column :datasets, :layer_info, :jsonb, default: []

    add_index :datasets, :application, using: :gin
    add_index :datasets, :layer_info, using: :gin
  end
end
