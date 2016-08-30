class Connector
  class << self
    def fetch_all(options, options_includes)
      connector_type = options['connector_type'].downcase          if options['connector_type'].present?
      status         = options['status'].downcase                  if options['status'].present?
      app            = options['app'].downcase                     if options['app'].present?
      includes       = options_includes['includes'].split(',')     if options_includes['includes'].present?


      datasets = Dataset.includes(:dateable).recent

      datasets = case connector_type
                 when 'rest' then datasets.filter_rest.recent
                 when 'json' then datasets.filter_json.recent
                 when 'doc'  then datasets.filter_doc.recent
                 when 'wms'  then datasets.filter_wms.recent
                 else
                   datasets
                 end

      datasets = app_filter(datasets, app) if app


      if status
        datasets = status_filter(datasets, status)
      else
        datasets = datasets.available
      end

      if includes && !datasets.empty?
        datasets.each do |dataset|
          dataset.populate(includes, app)
        end
      end

      return datasets
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

    def app_filter(scope, app)
      datasets = scope
      datasets = if app.present? && !app.include?('all')
                   datasets.filter_apps(app)
                 else
                   datasets.available
                 end

      datasets
    end

    def new(options)
      connector_type = options['connector_type']          if options['connector_type'].present?
      options        = options['connector_type'].present? ? options.except(:connector_type) : options
      case connector_type
      when 'json'
        options = options['data'].present?            ? options.except(:data)            : options
        options = options['data_attributes'].present? ? options.except(:data_attributes) : options
        options = options['connector_url'].present?   ? options.except(:connector_url)   : options
        options['table_name'] = json_table_name_param if options['table_name'].blank?
        JsonConnector.new(options)
      when 'document'
        DocConnector.new(options)
      when 'wms'
        WmsConnector.new(options)
      else
        if options['connector_provider'].present? && options['connector_provider'].include?('cartodb') && options['table_name'].blank?
          options['table_name'] = cartodb_table_name_param(options['connector_url'])
        elsif options['connector_provider'].present? && options['connector_provider'].include?('featureservice') && options['table_name'].blank?
          options['table_name'] = arcgis_table_name_param(options['connector_url'])
        else
          options
        end
        RestConnector.new(options)
      end
    end

    def cartodb_table_name_param(connector_url)
      if connector_url.include?('/tables/')
        URI(connector_url).path.split("/tables/")[1].split("/")[0]
      else
        URI.decode(connector_url).downcase.split('from ')[1].split(' ')[0]
      end
    end

    def arcgis_table_name_param(connector_url)
      URI(connector_url).path.split(/services|FeatureServer/)[1].gsub('/','')
    end

    def json_table_name_param
      'data'
    end
  end
end
