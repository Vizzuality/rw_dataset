# frozen_string_literal: true
require 'typhoeus'
require 'curb'
require 'uri'
require 'oj'

module Connection
  class << self
    def establish_connection(url, method, headers={}, body={})
      @request = ::Typhoeus::Request.new(URI.escape(url), method: method, headers: headers, body: body)
      @request.run
    end

    def populate_dataset(ids, app, ressource)
      options = {}
      options['dataset_id'] = ids unless ids.is_a?(Array)
      options['ids']        = ids if     ids.is_a?(Array)
      options['app']        = app if     app.present?

      get_resources(options, ressource)
    end

    def get_resources(options, ressource)
      headers = {}
      headers['Accept']         = 'application/json'
      headers['Content-Type']   = 'application/json'
      headers['authentication'] = Service::SERVICE_TOKEN

      body = {}
      if ressource.include?('metadata') || ressource.include?('vocabulary')
        body['ids'] = options['ids'] if options['ids'].present?
        body['app'] = options['app'] if options['ids'].present? && options['app'].present?
      else
        body[ressource] = {}
        body[ressource]['ids'] = options['ids'] if options['ids'].present?
        body[ressource]['app'] = options['app'] if options['ids'].present? && options['app'].present?
      end

      method = options['ids'].present? ? 'post' : 'get'

      url  = if ressource.include?('metadata') || ressource.include?('vocabulary')
               "#{Service::SERVICE_URL}/dataset"
             else
               "#{Service::SERVICE_URL}"
             end

      url += if options['ids'].present?
               "/#{ressource}/find-by-ids"
             elsif options['ids'].blank? && (ressource.include?('metadata') || ressource.include?('vocabulary'))
               "/#{options['dataset_id']}/#{ressource}"
             else
               "/dataset/#{options['dataset_id']}/#{ressource}"
             end

      if options['app'].present? && options['ids'].blank? && (ressource.include?('metadata') || ressource.include?('vocabulary'))
        url += "?application=#{options['app']}"
      elsif options['app'].present? && (ressource != 'metadata' || ressource != 'vocabulary')
        url += "?app=#{options['app']}"
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
        response.on_success { @data = Oj.load(curl.body_str.force_encoding(Encoding::UTF_8))['data'].map { |d| d['attributes'].merge({ id: d['id'] }) } }
        response.on_failure { @data = [] }
      end
    end
  end
end
