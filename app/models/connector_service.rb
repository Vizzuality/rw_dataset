require 'typhoeus'
require 'uri'

class ConnectorService
  class << self
    def establish_connection(url, method, body={})
      hydra    = Typhoeus::Hydra.new max_concurrency: 100
      @request = ::Typhoeus::Request.new(URI.escape(url), method: method, headers: { 'Accept' => 'application/json' }, body: { connector: body })

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
    end

    def connect_to_service(object_class, options)
      body = {}
      body['id']              = options['dataset_id']
      body['connector_url']   = options['connector_url']   if options['connector_url'].present?
      body['attributes_path'] = options['attributes_path'] if options['attributes_path'].present?
      body['data_columns']    = options['data_attributes'] if options['data_attributes'].present?
      body['data']            = options['data']            if options['data'].present?
      body['data_path']       = options['data_path']       if options['data_path'].present?

      service_url = if object_class.include?('JsonConnector')
                      "#{ENV['API_GATEWAY_URL']}/json-datasets"
                    else
                      "#{ENV['API_GATEWAY_URL']}/rest-datasets/cartodb"
                    end

      url  = service_url
      url += "/#{options['dataset_id']}" if options['to_delete'].present?
      url  = URI.decode(url)

      method = options['to_delete'].present? ? 'delete' : 'post'

      establish_connection(url, method, body)
    end
  end
end
