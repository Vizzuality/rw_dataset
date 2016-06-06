class DatasetArraySerializer < ActiveModel::Serializer
  attributes :id, :provider, :format, :name, :status

  def status
    object.status_txt
  end

  def provider
    object.dateable.try(:provider_txt)
  end

  def format
    object.try(:format_txt)
  end
end
