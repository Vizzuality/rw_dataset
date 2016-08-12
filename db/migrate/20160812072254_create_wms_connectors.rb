class CreateWmsConnectors < ActiveRecord::Migration[5.0]
  def change
    create_table :wms_connectors, id: :uuid, default: 'uuid_generate_v4()', force: true do |t|
      t.integer :connector_provider, default: 0, index: true

      t.timestamps
    end
  end
end
