# frozen_string_literal: true
module Clone
  extend ActiveSupport::Concern

  included do
    private

      def clone_dataset
        dataset_params['dataset_url'] = dataset_url_fixer
        user_id = if dataset_params['dataset_attributes']['user_id'].present?
                    dataset_params['dataset_attributes']['user_id']
                  elsif params['logged_user'].present?
                    params['logged_user']['id'] if params['logged_user']['id'].present?
                  else
                    nil
                  end
        if dataset_params['dataset_url'].present?
          JsonConnector.create(
            parent_connector_url: dataset_params['dataset_url'],
            parent_connector_provider: @dateable.attributes['connector_provider'],
            parent_connector_type: @dateable.class.name,
            parent_connector_id: @dataset.attributes['id'],
            parent_connector_data_path: 'data',
            dataset_attributes: {
              name: @dataset.attributes['name'] + '_copy',
              format: @dataset.attributes['format'],
              data_path: @dataset.attributes['data_path'],
              attributes_path: @dataset.attributes['attributes_path'],
              row_count: @dataset.attributes['row_count'],
              user_id: user_id,
              application: @dataset_apps
            }
          )
        end
      end

      def dataset_url_fixer
        dataset_params['dataset_url'].include?('http://') ? dataset_params['dataset_url'] : "#{Service::SERVICE_URL}#{dataset_params['dataset_url']}"
      end
  end

  class_methods {}
end
