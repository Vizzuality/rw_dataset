require 'uri'

class ConnectorService
  class << self
    def connect_to_service(object_class, options)
      body = {}
      body['id']              = options['dataset_id']
      body['data_id']         = options['data_id']         if options['data_id'].present?
      body['connector_url']   = options['connector_url']   if options['connector_url'].present?
      body['attributes_path'] = options['attributes_path'] if options['attributes_path'].present?
      body['data_columns']    = options['data_attributes'] if options['data_attributes'].present?
      body['data']            = options['data']            if options['data'].present?
      body['data_path']       = options['data_path']       if options['data_path'].present?
      body['table_name']      = options['table_name']      if options['table_name'].present?

      headers = {}
      headers['Accept']         = 'application/json'
      headers['authentication'] = ServiceSetting.auth_token if ServiceSetting.auth_token.present?

      service_url = case object_class
                    when 'JsonConnector' then "#{ServiceSetting.gateway_url}/json-datasets"
                    when 'RestConnector' then "#{ServiceSetting.gateway_url}/rest-datasets/#{options['provider']}"
                    when 'DocConnector'  then "#{ServiceSetting.gateway_url}/doc-datasets/#{options['provider']}"
                    end

      url  = service_url
      url += "/#{options['dataset_id']}"   if options['to_delete'].present? || options['to_update'].present? || options['data_to_update'].present? || options['overwrite'].present?
      url += "/data/#{options['data_id']}" if options['data_to_update'].present?
      url += '/data-overwrite'             if options['overwrite'].present?
      url  = URI.decode(url)

      method = options['to_delete'].present? ? 'delete' : 'post'

      ConcernConnection.establish_connection(url, method, headers, { connector: body })
    end
  end
end
