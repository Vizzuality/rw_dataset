class AddConnectorUrlToJsonDataset < ActiveRecord::Migration[5.0]
  def change
    add_column :json_connectors, :connector_url, :string
  end
end
