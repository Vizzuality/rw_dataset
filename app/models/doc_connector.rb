# frozen_string_literal: true
# == Schema Information
#
# Table name: doc_connectors
#
#  id                 :uuid             not null, primary key
#  connector_provider :integer          default("csv")
#  connector_url      :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  table_name         :string
#

class DocConnector < ApplicationRecord
  self.table_name = :doc_connectors

  PROVIDER = %w(csv).freeze

  enum connector_provider: { csv: 0 }

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
    params_for_adapter['dataset_id']    = dataset.id
    params_for_adapter['connector_url'] = connector_url
    params_for_adapter['provider']      = 'csv'
    params_for_adapter['table_name']    = table_name
    params_for_adapter['polygon']       = options['polygon'] if options['polygon'].present?
    params_for_adapter['point']         = {} if options['point'].present?
    params_for_adapter['point']['lat']  = options['point']['lat']  if params_for_adapter['point'] && options['point']['lat'].present?
    params_for_adapter['point']['long'] = options['point']['long'] if params_for_adapter['point'] && options['point']['long'].present?
    params_for_adapter['to_delete']     = true if options.include?('delete')
    params_for_adapter['to_update']     = true if options['to_update'].present?
    params_for_adapter['legend']        = dataset.legend if dataset.legend.present?

    ConnectorServiceJob.perform_later(object, params_for_adapter)
    dataset.update_attributes(status: 0)
  end
end
