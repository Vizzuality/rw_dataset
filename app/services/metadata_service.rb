require 'typhoeus'
require 'uri'

module MetadataService
  class << self
    def populate_dataset(ids, app=nil)
      options = {}
      options['dataset_id'] = ids unless ids.is_a?(Array)
      options['ids']        = ids if     ids.is_a?(Array)
      options['app']        = app if     app.present?

      get_metadata(options)
    end

    def get_metadata(options)
      headers = {}
      headers['Accept']         = 'application/json'
      headers['authentication'] = Service::SERVICE_TOKEN

      url  = "#{Service::SERVICE_URL}/metadata"
      # url = "http://api.resourcewatch.org/metadata"
      url += if options['ids'].present?
               "/find-by-ids"
             else
               "/#{options['dataset_id']}"
             end

      url += "/#{options['app']}" if options['app'].present? && options['ids'].blank?
      url  = URI.decode(url)

      method = options['ids'].present? ? 'post' : 'get'
      body = {}
      body['ids'] = options['ids'] if options['ids'].present?
      body['app'] = options['app'] if options['ids'].present? && options['app'].present?

      @request = ::Typhoeus::Request.new(URI.escape(url), method: method, headers: headers, body: body)

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
