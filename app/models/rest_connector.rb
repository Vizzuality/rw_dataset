# frozen_string_literal: true
# == Schema Information
#
# Table name: rest_connectors
#
#  id                 :uuid             not null, primary key
#  connector_provider :integer          default("cartodb")
#  connector_url      :string
#  table_name         :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class RestConnector < ApplicationRecord
  self.table_name = :rest_connectors

  PROVIDER = %w(cartodb featureservice gee).freeze

  enum connector_provider: { cartodb: 0, featureservice: 1, gee: 2 }

  before_update :generate_table_name, if: 'connector_url_changed?'

  has_one :dataset, as: :dateable, dependent: :destroy, inverse_of: :dateable
  accepts_nested_attributes_for :dataset, allow_destroy: true, update_only: true

  def provider_txt
    connector_provider
  end

  def self.parent_provider_txt(parent_connector_provider)
    PROVIDER[parent_connector_provider - 0]
  end

  def connect_to_service(options)
    object = self.class.name
    params_for_adapter = {}
    params_for_adapter['dataset_id']      = dataset.id
    params_for_adapter['connector_url']   = connector_url
    params_for_adapter['table_name']      = build_table_name_for_send
    params_for_adapter['provider']        = connector_provider
    params_for_adapter['data_path']       = dataset.data_path

    params_for_adapter['attributes_path'] = dataset.attributes_path
    params_for_adapter['to_delete']       = true           if options.include?('delete')
    params_for_adapter['to_update']       = true           if options['to_update'].present?
    params_for_adapter['legend']          = dataset.legend if dataset.legend.present?

    ConnectorServiceJob.perform_later(object, params_for_adapter)
    dataset.update_attributes(status: 0)
  end

  def build_table_name_for_send
    if self.connector_provider.include?('cartodb')
      Connector.cartodb_table_name_param(connector_url)
    elsif self.connector_provider.include?('gee')
      table_name
    end
  end

  private

    def generate_table_name
      self.table_name = if self.connector_provider.include?('cartodb')
                          Connector.cartodb_table_name_param(self.connector_url)
                        else
                          Connector.arcgis_table_name_param(self.connector_url)
                        end
    end
end
