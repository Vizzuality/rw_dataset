require 'uri'

class MetadataService
  class << self

    def populate_datasets(datasets, app)
      options = {}

      datasets.each do |dataset|
       dataset.metadata = populate_dataset(dataset[:id], app)
      end

      return datasets

    end

    def populate_dataset(id, app)
      options = {}
      options['id_dataset'] = id
      if app
        options['app'] = app
      end
      data = get_metadata(options)

      return data

    end


    def get_metadata(options)
      headers = {}
      headers['Accept']         = 'application/json'
      headers['authentication'] = ServiceSetting.auth_token if ServiceSetting.auth_token.present?

      service_url = "#{ServiceSetting.gateway_url}/metadata/#{options['id_dataset']}"
      if options.has_key?('app')
        service_url = "#{service_url}/#{options['app']}"
      end

      url  = service_url
      url  = URI.decode(url)

      method = 'get'

      data = ConcernConnection.establish_connection(url, method, headers)
      if data.response_code == 200
        return decode_jsonapi(ActiveSupport::JSON.decode(data.response_body))
      end
      return []
    end

    def decode_jsonapi(result)
      metadatas = []

      result['data'].each do |metadata|
        metadatas.push(metadata['attributes'])
      end
      return metadatas
    end
  end
end
