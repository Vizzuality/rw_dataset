class CreateDatasets < ActiveRecord::Migration[5.0]
  def up
    enable_extension 'citext'
    create_table :datasets do |t|
      t.jsonb    :data_columns, default: '[]'
      t.jsonb    :data, default: '{}'
      t.integer :format, default: 0
      t.integer :row_count
      t.integer :dateable_id
      t.string  :dateable_type

      t.timestamps
    end

    add_index :datasets, ['dateable_id', 'dateable_type'], name: 'index_datasets_on_connector_and_connector_type', unique: true
    add_index :datasets, ['data'], using: :gin
  end

  def down
    if ActiveRecord::Base.connection.table_exists? 'datasets'
      drop_table :datasets
    end
  end
end
