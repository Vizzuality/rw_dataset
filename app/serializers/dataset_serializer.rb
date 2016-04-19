class DatasetSerializer < ActiveModel::Serializer
  attributes :id, :provider, :format, :connector_name, :connector_path

  def attributes
    data = super
    data['connector_url']   = object.dateable.try(:connector_url) if object.dateable.try(:connector_url).present?
    data['table_name']      = object.dateable.try(:table_name)    if object.dateable.try(:table_name).present?
    data['data_attributes'] = object.try(:data_columns)
    data['cloned_host']     = cloned_host if cloned_host.any?
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

  def cloned_host
    data = {}
    data['host_provider'] = object.dateable.parent_provider_txt         if object.dateable.try(:parent_connector_provider).present?
    data['host_url']      = object.dateable.try(:parent_connector_url)  if object.dateable.try(:parent_connector_url).present?
    data['host_id']       = object.dateable.try(:parent_connector_id)   if object.dateable.try(:parent_connector_id).present?
    data['host_type']     = object.dateable.try(:parent_connector_type) if object.dateable.try(:parent_connector_type).present?
    data
  end
end
