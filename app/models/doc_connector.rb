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

  enum connector_provider: { csv: 0 }

  has_one :dataset, as: :dateable, dependent: :destroy, inverse_of: :dateable
  accepts_nested_attributes_for :dataset, allow_destroy: true, update_only: true

  def provider_txt
    connector_provider
  end

  def connect_to_service(options)
    object = self.class.name
    params_for_adapter = {}
    params_for_adapter['dataset_id']    = dataset.id
    params_for_adapter['connector_url'] = connector_url
    params_for_adapter['provider']      = 'csv'
    params_for_adapter['table_name']    = table_name
    params_for_adapter['to_delete']     = true if options.include?('delete')
    params_for_adapter['to_update']     = true if options['to_update'].present?

    ConnectorServiceJob.perform_later(object, params_for_adapter)
    dataset.update_attributes(status: 0)
  end
end
