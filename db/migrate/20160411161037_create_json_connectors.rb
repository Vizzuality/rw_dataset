class CreateJsonConnectors < ActiveRecord::Migration[5.0]
  def change
    create_table :json_connectors do |t|
      t.string  :connector_name
      t.integer :connector_format, default: 0
      t.string  :connector_path
      t.string  :attributes_path
      t.integer :connector_provider, default: 0
      t.string  :parent_connector_url
      t.integer :parent_connector_id
      t.string  :parent_connector_type
      t.string  :parent_connector_provider

      t.timestamps
    end
  end
end
