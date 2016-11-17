# frozen_string_literal: true
class Connector
  class << self
    def new(options)
      connector_type = options['connector_type'] if options['connector_type'].present?
      options        = if options['connector_type'].present? || options['logged_user'].present?
                         options.except(:connector_type, :logged_user)
                       else
                         options
                       end

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
  end
end
