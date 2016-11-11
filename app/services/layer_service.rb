# frozen_string_literal: true
require 'curb'
require 'uri'
require 'oj'

module LayerService
  class << self
    def populate_dataset(ids, app=nil)
      options = {}
      options['dataset_id'] = ids unless ids.is_a?(Array)
      options['ids']        = ids if     ids.is_a?(Array)
      options['app']        = app if     app.present?

      get_layer(options)
    end

    def get_layer(options)
      headers = {}
      headers['Accept']         = 'application/json'
      headers['Content-Type']   = 'application/json'
      headers['authentication'] = Service::SERVICE_TOKEN

      body = {}
      body['layer'] = {}
      body['layer']['ids'] = options['ids'] if options['ids'].present?
      body['layer']['app'] = options['app'] if options['ids'].present? && options['app'].present?

      method = options['ids'].present? ? 'post' : 'get'

      if options['ids'].present?
        url  = "#{Service::SERVICE_URL}/layer/find-by-ids"
      else
        url  = "#{Service::SERVICE_URL}/dataset"
        url += "/#{options['dataset_id']}/layer"
        url += "?app=#{options['app']}" if options['app'].present?
      end

      url  = URI.decode(url)

      begin
        if method.include?('post')
          @c = Curl::Easy.http_post(URI.escape(url), Oj.dump(body)) do |curl|
            each_curl(curl, headers)
          end
        else
          @c = Curl::Easy.http_get(URI.escape(url)) do |curl|
            each_curl(curl, headers)
          end
        end
        @c.perform
        @data
      rescue Curl::Err::TimeoutError
        []
      end
    end

    def each_curl(curl, headers)
      curl.headers = headers
      curl.follow_location = true
      curl.timeout_ms = 3000
      curl.on_complete do |response|
        response.on_success { @data = Oj.load(curl.body_str.force_encoding(Encoding::UTF_8))['data'].map { |d| d['attributes'] } }
        response.on_failure { @data = [] }
      end
    end
  end
end
