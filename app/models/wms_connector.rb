# == Schema Information
#
# Table name: wms_connectors
#
#  id                 :uuid             not null, primary key
#  connector_provider :integer          default("wms")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class WmsConnector < ApplicationRecord
  self.table_name = :wms_connectors

  PROVIDER = %w(wms).freeze

  enum connector_provider: { wms: 0 }

  has_one :dataset, as: :dateable, dependent: :destroy, inverse_of: :dateable
  accepts_nested_attributes_for :dataset, allow_destroy: true, update_only: true

  def provider_txt
    connector_provider
  end

  def self.parent_provider_txt(parent_connector_provider)
    PROVIDER[parent_connector_provider - 0]
  end

  def connect_to_service(options)
    dataset.update_attributes(status: 1)
  end
end
