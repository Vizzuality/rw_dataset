class DatasetArraySerializer < ActiveModel::Serializer
  attributes :id, :provider, :format, :connector_name, :connector_path

  def attributes
    data = super
    data['connector_url']   = object.dateable.try(:connector_url) if object.dateable.try(:connector_url).present?
    data['table_name']      = object.dateable.try(:table_name)    if object.dateable.try(:table_name).present?
    data['data_attributes'] = object.try(:data_columns)
    data
  end

  def connector_name
    object.dateable.try(:connector_name)
  end

  def connector_path
    object.dateable.try(:connector_path)
  end

  def provider
    object.dateable.try(:provider_txt)
  end

  def format
    object.dateable.try(:format_txt)
  end
end
