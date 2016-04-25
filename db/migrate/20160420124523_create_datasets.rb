class CreateDatasets < ActiveRecord::Migration[5.0]
  def change
    create_table :datasets, id: :uuid, default: 'uuid_generate_v4()', force: true do |t|
      t.uuid    :dateable_id
      t.string  :dateable_type
      t.string  :name
      t.integer :format,             default: 0
      t.string  :data_path
      t.string  :attributes_path
      t.integer :row_count
      t.integer :status,             default: 0       # status(in process - 0, saved - 1, failed - 2)

      t.timestamps
    end

    add_index :datasets, ['dateable_id', 'dateable_type'], name: 'index_datasets_on_connector_and_connector_type', unique: true
  end
end
