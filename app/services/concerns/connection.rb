# frozen_string_literal: true
require 'typhoeus'
require 'uri'

module Connection
  class << self
    def establish_connection(url, method, headers={}, body={})
      @request = ::Typhoeus::Request.new(URI.escape(url), method: method, headers: headers, body: body)
      @request.run
    end
  end
end
