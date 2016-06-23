# == Schema Information
#
# Table name: rest_connectors
#
#  id                 :uuid             not null, primary key
#  connector_provider :integer          default(0)
#  connector_url      :string
#  table_name         :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class RestConnector < ApplicationRecord
  self.table_name = :rest_connectors

  PROVIDER = %w(CartoDb Arcgis).freeze

  has_one :dataset, as: :dateable, dependent: :destroy, inverse_of: :dateable
  accepts_nested_attributes_for :dataset, allow_destroy: true, update_only: true

  def provider_txt
    PROVIDER[connector_provider - 0]
  end

  def self.parent_provider_txt(parent_connector_provider)
    PROVIDER[parent_connector_provider - 0]
  end

  def connect_to_service(options)
    object = self.class.name
    params_for_adapter = {}
    params_for_adapter['dataset_id']      = dataset.id
    params_for_adapter['connector_url']   = connector_url
    params_for_adapter['provider']        = case connector_provider
                                            when 0 then 'cartodb'
                                            when 1 then 'arcgis'
                                            end

    params_for_adapter['attributes_path'] = dataset.attributes_path
    params_for_adapter['to_delete']       = true if options.include?('delete')

    ConnectorServiceJob.perform_later(object, params_for_adapter)
    dataset.update_attributes(status: 0)
  end
end
