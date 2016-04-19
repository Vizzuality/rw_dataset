class JsonConnector < ApplicationRecord
  self.table_name = :json_connectors

  FORMAT          = %w(JSON).freeze
  PROVIDER        = %w(RwJson).freeze
  PARENT_PROVIDER = %w(CartoDb).freeze

  has_one :dataset, as: :dateable, dependent: :destroy, inverse_of: :dateable

  accepts_nested_attributes_for :dataset, allow_destroy: true

  def format_txt
    FORMAT[connector_format - 0]
  end

  def provider_txt
    PROVIDER[connector_provider - 0]
  end

  def parent_provider_txt
    PARENT_PROVIDER[connector_provider - 0]
  end
end
