require 'typhoeus'
require 'uri'

class ConcernConnection
  class << self
    def establish_connection(url, method, headers={}, body={})
      @request = ::Typhoeus::Request.new(URI.escape(url), method: method, headers: headers, body: body)
      @request.run
    end
  end
end