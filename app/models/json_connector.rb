# frozen_string_literal: true
# == Schema Information
#
# Table name: json_connectors
#
#  id                         :uuid             not null, primary key
#  connector_provider         :integer          default("rwjson")
#  parent_connector_url       :string
#  parent_connector_id        :uuid
#  parent_connector_type      :string
#  parent_connector_provider  :integer
#  parent_connector_data_path :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  table_name                 :string
#

require 'oj'

class JsonConnector < ApplicationRecord
  self.table_name = :json_connectors

  PROVIDER = %w(rwjson).freeze

  enum connector_provider: { rwjson: 0 }

  has_one :dataset, as: :dateable, dependent: :destroy, inverse_of: :dateable
  accepts_nested_attributes_for :dataset, allow_destroy: true, update_only: true

  def provider_txt
    connector_provider
  end

  def parent_connector_provider_txt
    parent_connector_type.constantize.parent_provider_txt(parent_connector_provider) if parent_connector_type.present?
  end

  def self.parent_provider_txt(parent_connector_provider)
    PROVIDER[parent_connector_provider - 0]
  end

  def connect_to_service(options)
    object = self.class.name
    params_for_adapter = {}
    params_for_adapter['dataset_id']      = dataset.id
    params_for_adapter['data_id']         = options['data_id'] if options['data_id'].present?
    params_for_adapter['data_path']       = if options['data_path'].present?
                                              options['data_path']
                                            elsif self.try(:parent_connector_data_path).present?
                                              self.try(:parent_connector_data_path)
                                            else
                                              dataset.data_path
                                            end

    params_for_adapter['attributes_path'] = dataset.attributes_path if dataset.attributes_path.present?

    params_for_adapter['connector_url']   = dataset_url_fixer(options['connector_url'])
    params_for_adapter['data_attributes'] = Oj.dump(options['data_attributes']) if options['data_attributes'].present?
    params_for_adapter['data']            = Oj.dump(options['data'])            if options['data'].present?
    params_for_adapter['to_delete']       = true                                if options.include?('delete') || options['to_delete'].present?
    params_for_adapter['to_update']       = true                                if options['to_update'].present?
    params_for_adapter['data_to_update']  = true                                if options['data_to_update'].present?
    params_for_adapter['overwrite']       = true                                if options['overwrite'].present?
    params_for_adapter['legend']          = dataset.legend                      if dataset.legend.present?

    ConnectorServiceJob.perform_later(object, params_for_adapter)
    dataset.update_attributes(status: 0)
  end

  def dataset_url_fixer(options_connector_url=nil)
    connector_url = if self.parent_connector_url.present?
                      self.parent_connector_url
                    else
                      options_connector_url
                    end

    connector_url.present? && connector_url.include?('http') ? connector_url : "#{Service::SERVICE_URL}#{connector_url}"
  end
end
