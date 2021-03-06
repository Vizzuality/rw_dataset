# frozen_string_literal: true
require 'uri'

module ConnectorService
  class << self
    def connect_to_service(object_class, options)
      body = {}
      body['id']              = options['dataset_id']
      body['connector_url']   = options['connector_url']   if options['connector_url'].present?
      body['attributes_path'] = options['attributes_path'] if options['attributes_path'].present?
      body['data_columns']    = options['data_attributes'] if options['data_attributes'].present?
      body['data']            = options['data']            if options['data'].present?
      body['data_path']       = options['data_path']       if options['data_path'].present?
      body['table_name']      = options['table_name']      if options['table_name'].present?
      body['polygon']         = options['polygon']         if options['polygon'].present?
      body['point']           = options['point']           if options['point'].present?
      body['legend']          = options['legend']          if options['legend'].present?

      headers = {}
      headers['Accept']         = 'application/json'
      headers['authentication'] = Service::SERVICE_TOKEN

      url = case object_class
            when 'JsonConnector' then "#{Service::SERVICE_URL}/json-datasets"
            when 'RestConnector' then "#{Service::SERVICE_URL}/rest-datasets/#{options['provider']}"
            when 'DocConnector'  then "#{Service::SERVICE_URL}/doc-datasets/#{options['provider']}"
            end

      url += "/#{options['dataset_id']}" if options['to_delete'].present? || options['to_update'].present?
      url  = URI.decode(url)

      method = options['to_delete'].present? ? 'delete' : 'post'

      Connection.establish_connection(url, method, headers, { connector: body })
    end
  end
end
