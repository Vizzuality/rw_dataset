require 'uri'

module TagService
  class << self
    def connect_to_service(object_class, options)
      body = options

      headers = {}
      headers['Accept']         = 'application/json'
      headers['authentication'] = Service::SERVICE_TOKEN

      url = "#{Service::SERVICE_URL}/tags"
      url = URI.decode(url)

      method = 'post'

      Connection.establish_connection(url, method, headers, { tag: body })
    end
  end
end
