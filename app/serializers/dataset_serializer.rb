class DatasetSerializer < ActiveModel::Serializer
  attributes :id, :connector_name, :provider, :format

  has_many :rest_connector_params
  has_one  :dataset, key: 'dataset_meta'

  def provider
    object.provider_txt
  end

  def format
    object.format_txt
  end

  def include_associations!
    include! :rest_connector_params, serializer: ParamsSerializer
    include! :dataset,               serializer: DatasetMetaSerializer
  end
end