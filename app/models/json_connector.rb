# == Schema Information
#
# Table name: json_connectors
#
#  id                         :uuid             not null, primary key
#  connector_provider         :integer          default("0")
#  parent_connector_url       :string
#  parent_connector_id        :integer
#  parent_connector_type      :string
#  parent_connector_provider  :integer
#  parent_connector_data_path :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#

require 'oj'

class JsonConnector < ApplicationRecord
  self.table_name = :json_connectors

  PROVIDER = %w(RwJson).freeze

  has_one :dataset, as: :dateable, dependent: :destroy, inverse_of: :dateable
  accepts_nested_attributes_for :dataset, allow_destroy: true, update_only: true

  def provider_txt
    PROVIDER[connector_provider - 0]
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
    params_for_adapter['data_path']       = self.try(:parent_connector_data_path)
    params_for_adapter['connector_url']   = self.try(:parent_connector_url)
    params_for_adapter['data_attributes'] = Oj.dump(options['data_attributes']) if options['data_attributes'].present?
    params_for_adapter['data']            = Oj.dump(options['data'])            if options['data'].present?

    ConnectorServiceJob.perform_later(object, params_for_adapter)
  end
end
