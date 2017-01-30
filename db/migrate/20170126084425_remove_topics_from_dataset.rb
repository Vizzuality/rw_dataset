class RemoveTopicsFromDataset < ActiveRecord::Migration[5.0]
  def change
    remove_column :datasets, :topics
  end
end
