require 'typhoeus'
require 'uri'

class TagService
  class << self
    def establish_connection(url, method, body={})
      @request = ::Typhoeus::Request.new(URI.escape(url), method: method, headers: { 'Accept' => 'application/json' }, body: { tag: body })
      @request.run
    end

    def connect_to_service(options)
      body = options
      url  = "#{ENV['API_GATEWAY_URL']}/tags"
      url  = URI.decode(url)

      method = 'post'

      establish_connection(url, method, body)
    end
  end
end
