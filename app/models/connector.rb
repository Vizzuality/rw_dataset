# frozen_string_literal: true
class Connector
  class << self
    def fetch_all(options)
      connector_type = options['connector_type'].downcase if options['connector_type'].present?
      status         = options['status'].downcase         if options['status'].present?
      app            = options['app'].downcase            if options['app'].present?
      including      = options['includes']                if options['includes'].present?

      cache_options   = ''
      cache_options  += "_#{connector_type}"     if connector_type.present?
      cache_options  += "_status:#{status}"      if status.present?
      cache_options  += "_app:#{app}"            if app.present?
      cache_options  += "_includes:#{including}" if including.present?

      if datasets = Rails.cache.read(cache_key(cache_options))
        datasets
      else
        datasets = Dataset.includes(:dateable).recent
        datasets = case connector_type
                   when 'rest' then datasets.filter_rest.recent
                   when 'json' then datasets.filter_json.recent
                   when 'doc'  then datasets.filter_doc.recent
                   when 'wms'  then datasets.filter_wms.recent
                   else
                     datasets
                   end

        datasets = app_filter(datasets, app) if app.present?

        datasets = if status.present?
                     status_filter(datasets, status)
                   else
                     datasets.available
                   end

        datasets = includes_filter(datasets, including, app) if including.present? && datasets.any?

        Rails.cache.write(cache_key(cache_options), datasets.to_a)
      end
      datasets
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

    def includes_filter(scope, including, app)
      datasets    = scope
      dataset_ids = datasets.to_a.pluck(:id)
      including   = including.split(',') if including.present?
      app         = app                  if app.present? && !app.include?('all')

      including.each do |include|
        case include
        when 'metadata'
          Metadata.data = MetadataService.populate_dataset(dataset_ids, app)
          datasets = datasets.each do |dataset|
                       dataset.metadata = Metadata.where(dataset: dataset.id)
                     end
        end
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
        options = options['polygon'].present? ? options.except(:polygon) : options
        options = options['point'].present?   ? options.except(:point)   : options
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

    def cache_key(cache_options)
      "datasets_#{ cache_options }"
    end
  end
end
