class AddTableNameToJsonConnector < ActiveRecord::Migration[5.0]
  def change
    add_column :json_connectors, :table_name, :string
  end
end
