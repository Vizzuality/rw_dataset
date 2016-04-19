require 'typhoeus'
require 'uri'
require 'oj'

class ConnectorService
  def self.connect_to_provider(connector_url, data_path)
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

    Oj.load(@request.response.body.force_encoding(Encoding::UTF_8))[data_path] || Oj.load(@request.response.body.force_encoding(Encoding::UTF_8))
  end
end
