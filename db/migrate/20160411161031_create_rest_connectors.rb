class CreateRestConnectors < ActiveRecord::Migration[5.0]
  def change
    create_table :rest_connectors do |t|
      t.string  :connector_name
      t.string  :connector_url
      t.integer :connector_format, default: 0
      t.string  :connector_path
      t.integer :connector_provider, default: 0
      t.string  :attributes_path
      t.string  :table_name

      t.timestamps
    end
  end
end
