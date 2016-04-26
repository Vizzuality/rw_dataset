class CreateRestConnectors < ActiveRecord::Migration[5.0]
  def change
    create_table :rest_connectors, id: :uuid, default: 'uuid_generate_v4()', force: true do |t|
      t.integer :connector_provider, default: 0, index: true
      t.string  :connector_url
      t.string  :table_name

      t.timestamps
    end
  end
end
