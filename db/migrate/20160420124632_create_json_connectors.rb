class CreateJsonConnectors < ActiveRecord::Migration[5.0]
  def change
    create_table :json_connectors, id: :uuid, default: 'uuid_generate_v4()', force: true do |t|
      t.integer :connector_provider, default: 0, index: true
      t.string  :parent_connector_url
      t.integer :parent_connector_id
      t.string  :parent_connector_type
      t.integer :parent_connector_provider

      t.timestamps
    end
  end
end
