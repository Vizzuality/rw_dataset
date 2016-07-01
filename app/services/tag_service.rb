require 'uri'

class TagService
  class << self
    def connect_to_service(object_class, options)
      body = options

      headers = {}
      headers['Accept']         = 'application/json'
      headers['authentication'] = ServiceSetting.auth_token if ServiceSetting.auth_token.present?

      service_url = "#{ServiceSetting.gateway_url}/tags"

      url  = service_url
      url  = URI.decode(url)

      method = 'post'

      ConcernConnection.establish_connection(url, method, headers, { tag: body })
    end
  end
end
