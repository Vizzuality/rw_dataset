require 'typhoeus'
require 'uri'
require 'oj'

class RestConnector < ApplicationRecord
  self.table_name = :rest_connectors

  FORMAT   = %w(JSON).freeze
  PROVIDER = %w(CartoDb).freeze

  has_many :rest_connector_params, foreign_key: 'connector_id'

  has_one  :dataset, as: :dateable, dependent: :destroy, inverse_of: :dateable

  after_create  :recive_meta_data
  before_update :recive_meta_data, if: 'connector_url_changed?'

  # TODO: Validation for connector_url - defined table_name is part of connector_url?
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

    def recive_meta_data
      url      = URI.decode(connector_url)
      hydra    = Typhoeus::Hydra.new max_concurrency: 100
      @request = ::Typhoeus::Request.new(URI.escape(url), method: :get, followlocation: true)

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

      recive_attributes = Oj.load(@request.response.body.force_encoding(Encoding::UTF_8))[attributes_path]
      dataset.update_attributes(table_columns: recive_attributes)
    end
end
