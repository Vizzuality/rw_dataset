class AddTopicsToDatasets < ActiveRecord::Migration[5.0]
  def change
    add_column :datasets, :topics, :jsonb, default: []
    add_index :datasets, :topics, using: :gin
  end
end
