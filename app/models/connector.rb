class Connector
  class << self
    def fetch_all(options)
      connector_type = options['connector_type'] if options['connector_type'].present?

      case connector_type
      when 'rest' then Dataset.filter_rest.recent
      when 'json' then Dataset.filter_json.recent
      else
        Dataset.includes(:dateable).recent
      end
    end

    def new(options)
      connector_type = options['connector_type'] if options['connector_type'].present?
      options = options['connector_type'].present? ? options.except(:connector_type) : options
      case connector_type
      when 'json' then JsonConnector.new(options)
      else
        RestConnector.new(options)
      end
    end
  end
end
