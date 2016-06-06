class Connector
  class << self
    def fetch_all(options)
      connector_type = options['connector_type'] if options['connector_type'].present?
      status         = options['status']         if options['status'].present?

      datasets = Dataset.includes(:dateable).recent

      datasets = case connector_type
                 when 'rest' then datasets.filter_rest.recent
                 when 'json' then datasets.filter_json.recent
                 else
                   datasets
                 end

      if status
        status_filter(datasets, status)
      else
        datasets.available
      end
    end

    def status_filter(scope, status)
      datasets = scope
      datasets = case status
                 when 'pending'  then datasets.filter_pending
                 when 'active'   then datasets.filter_saved
                 when 'failed'   then datasets.filter_failed
                 when 'disabled' then datasets.filter_inactives
                 when 'all'      then datasets
                 else
                   datasets.available
                 end

      datasets
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
