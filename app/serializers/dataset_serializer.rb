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
#

class DatasetSerializer < ActiveModel::Serializer
  attributes :id, :application, :name, :data_path, :attributes_path, :provider, :format, :layers, :connector_url, :table_name, :tags, :cloned_host

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
    object.dateable.try(:table_name)
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
end
