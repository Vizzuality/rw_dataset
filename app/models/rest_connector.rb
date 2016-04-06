require 'typhoeus'
require 'uri'
require 'oj'

class RestConnector < ApplicationRecord
  self.table_name = :rest_connectors

  FORMAT   = %w(JSON)
  PROVIDER = %w(CartoDb)

  has_many :rest_connector_params, foreign_key: 'connector_id'

  has_one  :dataset, as: :dateable, dependent: :destroy, inverse_of: :dateable

  before_create :validate_data
  after_create  :get_meta_data
  before_update :get_meta_data, if: 'connector_url_changed?'

  # ToDo: Validation for connector_url - defined table_name is part of connector_url?
  # Separated provider specific functions

  accepts_nested_attributes_for :rest_connector_params, allow_destroy: true
  accepts_nested_attributes_for :dataset,               allow_destroy: true

  def format_txt
    FORMAT[connector_format - 0]
  end

  def provider_txt
    PROVIDER[connector_provider - 0]
  end

  private

    def validate_data
    end

    def get_meta_data
      url = connector_url
      url = URI.decode(url)
      url = URI.escape(url)

      hydra    = Typhoeus::Hydra.new max_concurrency: 100
      @request = ::Typhoeus::Request.new(url, method: :get, followlocation: true)

      @request.on_complete do |response|
        if response.success?
          # cool
        elsif response.timed_out?
          'got a time out'
        elsif response.code == 0
          response.return_message
        else
          'HTTP request failed: ' + response.code.to_s
        end
      end

      hydra.queue @request
      hydra.run

      get_attributes = Oj.load(@request.response.body.force_encoding(Encoding::UTF_8))[attributes_path]
      self.dataset.update_attributes(table_columns: get_attributes)
    end
end
