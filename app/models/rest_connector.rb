class RestConnector < ApplicationRecord
  self.table_name = :rest_connectors

  FORMAT   = %w(JSON).freeze
  PROVIDER = %w(CartoDb).freeze

  has_one :dataset, as: :dateable, dependent: :destroy, inverse_of: :dateable

  after_create :recive_meta_data
  after_update :update_meta_data, if: 'connector_url_changed?'

  accepts_nested_attributes_for :dataset, allow_destroy: true

  def format_txt
    FORMAT[connector_format - 0]
  end

  def provider_txt
    PROVIDER[connector_provider - 0]
  end

  private

    def connect_to_provider
      @recive_attributes = ConnectorService.connect_to_provider(connector_url, attributes_path)
    end

    def recive_meta_data
      connect_to_provider
      Dataset.create(data_columns: @recive_attributes, dateable_id: self.id, dateable_type: 'RestConnector')
    end

    def update_meta_data
      connect_to_provider
      dataset.update_attributes(data_columns: @recive_attributes)
    end
end
