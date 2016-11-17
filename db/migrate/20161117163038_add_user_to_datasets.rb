class AddUserToDatasets < ActiveRecord::Migration[5.0]
  def change
    add_column :datasets, :user_id, :string, index: true unless column_exists? :datasets, :user_id
  end
end
