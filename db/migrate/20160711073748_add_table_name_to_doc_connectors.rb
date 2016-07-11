class AddTableNameToDocConnectors < ActiveRecord::Migration[5.0]
  def change
    add_column :doc_connectors, :table_name, :string
  end
end
