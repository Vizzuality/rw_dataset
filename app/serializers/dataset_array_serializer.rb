class DatasetArraySerializer < ApplicationSerializer
  attributes :id, :provider, :format, :name, :status, :application, :layers

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
