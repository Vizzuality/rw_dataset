require 'typhoeus'
require 'uri'

class TagService
  class << self
    def establish_connection(url, method, headers={}, body={})
      @request = ::Typhoeus::Request.new(URI.escape(url), method: method, headers: headers, body: { tag: body })
      @request.run
    end

    def connect_to_service(options)
      body = options

      headers = {}
      headers['Accept']         = 'application/json'
      headers['authentication'] = ServiceSetting.auth_token if ServiceSetting.auth_token.present?

      url  = "#{ServiceSetting.gateway_url}/tags"
      url  = URI.decode(url)

      method = 'post'

      establish_connection(url, method. headers, body)
    end
  end
end
