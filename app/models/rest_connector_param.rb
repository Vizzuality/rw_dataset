class RestConnectorParam < ApplicationRecord
  self.table_name = :rest_connector_params

  belongs_to :rest_connector, class_name: 'RestConnector'

  PARAM_TYPES = %w(Header Query).freeze

  def param_type_txt
    PARAM_TYPES[param_type - 1]
  end

  def type_select
    PARAM_TYPES.map.with_index(1).to_a
  end
end
