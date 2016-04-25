class DatasetArraySerializer < ActiveModel::Serializer
  attributes :id, :provider, :format, :name, :meta

  def provider
    object.dateable.try(:provider_txt)
  end

  def format
    object.try(:format_txt)
  end

  def meta
    data = {}
    data['status']     = object.try(:status)
    data['updated_at'] = object.try(:updated_at)
    data['created_at'] = object.try(:created_at)
    data['rows']       = object.try(:row_count)
    data
  end
end
