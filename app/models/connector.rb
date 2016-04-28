class Connector
  class << self
    def fetch_all(options)
      connector_type = options['connector_type'] if options['connector_type'].present?

      case connector_type
      when 'rest' then Dataset.filter_rest.recent.available
      when 'json' then Dataset.filter_json.recent.available
      else
        Dataset.includes(:dateable).recent.available
      end
    end

    def new(options)
      connector_type = options['connector_type']          if options['connector_type'].present?
      options        = options['connector_type'].present? ? options.except(:connector_type)  : options
      case connector_type
      when 'json'
        options = options['data'].present?            ? options.except(:data)            : options
        options = options['data_attributes'].present? ? options.except(:data_attributes) : options
        JsonConnector.new(options)
      else
        RestConnector.new(options)
      end
    end
  end
end
