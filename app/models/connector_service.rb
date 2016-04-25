require 'typhoeus'
require 'uri'

class ConnectorService
  def self.connect_to_service(object_class, options)
    body = {}
    body['id']              = options['dataset_id']
    body['connector_url']   = options['connector_url']   if options['connector_url'].present?
    body['attributes_path'] = options['attributes_path'] if options['attributes_path'].present?
    body['data_columns']    = options['data_attributes'] if options['data_attributes'].present?
    body['data']            = options['data']            if options['data'].present?
    body['dataset_url']     = options['dataset_url']     if options['dataset_url'].present?
    # body['data_path']       = options['data_path']       if options['data_path'].present?

    url = if object_class.include?('JsonConnector')
            URI.decode("#{ENV['API_GATEWAY_URL']}/json-datasets")
          else
            URI.decode("#{ENV['API_GATEWAY_URL']}/rest-datasets/cartodb")
          end

    hydra    = Typhoeus::Hydra.new max_concurrency: 100
    @request = ::Typhoeus::Request.new(URI.escape(url), method: :post, headers: { 'Accept' => 'application/json' }, body: { connector: body })

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
end
