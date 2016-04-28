class DatasetSerializer < ActiveModel::Serializer
  attributes :id, :name, :data_path, :attributes_path, :provider, :format, :connector_url, :table_name, :cloned_host, :meta

  def provider
    object.dateable.try(:provider_txt)
  end

  def format
    object.try(:format_txt)
  end

  def connector_url
    object.dateable.try(:connector_url)
  end

  def table_name
    object.dateable.try(:table_name)
  end

  def cloned_host
    data = {}
    data['host_provider'] = object.dateable.try(:parent_connector_provider_txt)
    data['host_url']      = object.dateable.try(:parent_connector_url)
    data['host_id']       = object.dateable.try(:parent_connector_id)
    data['host_type']     = object.dateable.try(:parent_connector_type)
    data['host_path']     = object.dateable.try(:parent_connector_data_path)
    data
  end

  def meta
    data = {}
    data['status']     = object.try(:status_txt)
    data['updated_at'] = object.try(:updated_at)
    data['created_at'] = object.try(:created_at)
    data['rows']       = object.try(:row_count)
    data
  end
end
