class DatasetMetaSerializer < ActiveModel::Serializer
  attributes :connector_url, :connector_path, :table_name, :table_columns, :row_count

  def connector_url
    object.dateable.connector_url
  end

  def connector_path
    object.dateable.connector_path
  end
end
