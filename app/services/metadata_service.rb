require 'typhoeus'
require 'uri'

module MetadataService
  class << self
    def populate_dataset(dataset_id, app)
      options = {}
      options['dataset_id'] = dataset_id
      options['app']        = app if app.present?

      get_metadata(options)
    end

    def get_metadata(options)
      headers = {}
      headers['Accept']         = 'application/json'
      headers['authentication'] = Service::SERVICE_TOKEN

      url = "#{Service::SERVICE_URL}/metadata/#{options['dataset_id']}"
      url = "#{url}/#{options['app']}" if options['app'].present?
      url = URI.decode(url)

      @request = ::Typhoeus::Request.new(URI.escape(url), method: 'get', headers: headers)

      @request.on_complete do |response|
        if response.success?
          @data = Oj.load(response.body.force_encoding(Encoding::UTF_8))['data'].map { |d| d['attributes'] }
        elsif response.timed_out?
          @data = 'Meta data not reachable'
        elsif response.code.zero?
          @data = response.return_message
        else
          @data = []
        end
      end
      @request.run
      @data
    end
  end
end
