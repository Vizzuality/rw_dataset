require 'typhoeus'
require 'uri'

class RestConnector < ApplicationRecord
  self.table_name = :rest_connectors

  FORMAT   = %w(JSON)
  PROVIDER = %w(CartoDb)

  has_many :rest_connector_params, foreign_key: 'connector_id'

  has_one  :dataset, as: :dateable, dependent: :destroy, inverse_of: :dateable

  before_create :validate_data
  after_create  :get_meta_data

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

      @request = ::Typhoeus::Request.new(url, method: :get, followlocation: true)

      @request.on_complete do |response|
        if response.success?
          # cool
        elsif response.timed_out?
          # aw hell no
          # log("got a time out")
        elsif response.code == 0
          # Could not get an http response, something's wrong.
          # log(response.return_message)
        else
          # Received a non-successful http response.
          # log("HTTP request failed: " + response.code.to_s)
        end
      end

      response = @request.run
      get_attributes = JSON.parse(response.response_body)[attributes_path]
      self.dataset.update_attributes(table_columns: get_attributes)
    end
end
