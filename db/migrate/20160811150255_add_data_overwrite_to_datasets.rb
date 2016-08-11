class AddDataOverwriteToDatasets < ActiveRecord::Migration[5.0]
  def change
    add_column :datasets, :data_overwrite, :boolean, default: false
  end
end
