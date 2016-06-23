class AddTagsToDatasets < ActiveRecord::Migration[5.0]
  def change
    add_column :datasets, :tags, :jsonb, default: []
    add_index :datasets, :tags, using: :gin
  end
end
