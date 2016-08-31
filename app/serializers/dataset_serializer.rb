# == Schema Information
#
# Table name: datasets
#
#  id              :uuid             not null, primary key
#  dateable_id     :uuid
#  dateable_type   :string
#  name            :string
#  format          :integer          default(0)
#  data_path       :string
#  attributes_path :string
#  row_count       :integer
#  status          :integer          default(0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  tags            :jsonb
#  application     :jsonb
#  layer_info      :jsonb
#  data_overwrite  :boolean          default(FALSE)
#

class DatasetSerializer < ApplicationSerializer
  attributes :id, :application, :name, :subtitle, :data_path, :attributes_path, :provider, :format,
             :connector_url, :table_name, :layers, :tags, :metadata, :cloned_host, :meta

  def provider
    object.dateable.try(:provider_txt)
  end

  def format
    object.try(:format_txt)
  end

  def connector_url
    object.dateable.try(:connector_url)
  end

  def table_name
    return object.dateable.table_name if object.dateable.try(:table_name).present?
    case object.dateable.try(:connector_provider)
    when 'cartodb'
      Connector.cartodb_table_name_param(object.dateable.connector_url)
    when 'featureservice'
      Connector.arcgis_table_name_param(object.dateable.connector_url)
    when 'rwjson'
      Connector.json_table_name_param
    end
  end

  def metadata
    object.try(:metadata)
  end

  def layers
    object.try(:layer_info)
  end

  def cloned_host
    data = {}
    data['host_provider'] = object.dateable.try(:parent_connector_provider_txt)
    data['host_url']      = object.dateable.try(:parent_connector_url)
    data['host_id']       = object.dateable.try(:parent_connector_id)
    data['host_type']     = object.dateable.try(:parent_connector_type)
    data['host_path']     = object.dateable.try(:parent_connector_data_path)
    data
  end

  def meta
    data = {}
    data['status']     = object.try(:status_txt)
    data['overwrite']  = object.try(:data_overwrite)
    data['updated_at'] = object.try(:updated_at)
    data['created_at'] = object.try(:created_at)
    data['rows']       = object.try(:row_count)
    data
  end
end
