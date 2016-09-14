class DatasetArraySerializer < ApplicationSerializer
  attributes :id, :provider, :format, :name, :subtitle, :status, :application, :layers

  has_many :metadata, serializer: MetadataSerializer

  def status
    object.status_txt
  end

  def provider
    object.dateable.try(:provider_txt)
  end

  def format
    object.try(:format_txt)
  end

  def layers
    object.try(:layer_info)
  end
end
