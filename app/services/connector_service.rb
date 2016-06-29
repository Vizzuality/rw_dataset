require 'typhoeus'
require 'uri'

class ConnectorService
  class << self
    def establish_connection(url, method, headers={}, body={})
      @request = ::Typhoeus::Request.new(URI.escape(url), method: method, headers: headers, body: { connector: body })
      @request.run
    end

    def connect_to_service(object_class, options)
      body = {}
      body['id']              = options['dataset_id']
      body['connector_url']   = options['connector_url']   if options['connector_url'].present?
      body['attributes_path'] = options['attributes_path'] if options['attributes_path'].present?
      body['data_columns']    = options['data_attributes'] if options['data_attributes'].present?
      body['data']            = options['data']            if options['data'].present?
      body['data_path']       = options['data_path']       if options['data_path'].present?


      # for Csv
      # connector_url, id

      headers = {}
      headers['Accept']         = 'application/json'
      headers['authentication'] = ServiceSetting.auth_token if ServiceSetting.auth_token.present?

      service_url = case object_class
                    when 'JsonConnector' then "#{ServiceSetting.gateway_url}/json-datasets"
                    when 'RestConnector' then "#{ServiceSetting.gateway_url}/rest-datasets/#{options['provider']}"
                    when 'DocConnector'  then "#{ServiceSetting.gateway_url}/doc-datasets/#{options['provider']}"
                    end

      url  = service_url
      url += "/#{options['dataset_id']}" if options['to_delete'].present?
      url  = URI.decode(url)

      method = options['to_delete'].present? ? 'delete' : 'post'

      establish_connection(url, method, headers, body)
    end
  end
end
