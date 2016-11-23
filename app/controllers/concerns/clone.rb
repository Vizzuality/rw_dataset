# frozen_string_literal: true
module Clone
  extend ActiveSupport::Concern

  included do
    def clone
      authorized = User.authorize_user!(@user, @dataset_apps)
      if authorized.present?
        @dataset = clone_dataset.dataset
        if @dataset&.save
          @dataset.dateable.connect_to_service(dataset_params)
          render json: @dataset, status: 201, serializer: DatasetSerializer, meta: { status: @dataset.try(:status_txt),
                                                                                     overwrite: @dataset.try(:data_overwrite),
                                                                                     updated_at: @dataset.try(:updated_at),
                                                                                     created_at: @dataset.try(:created_at) }
        else
          render json: { errors: [{ status: 422, title: 'Error cloning dataset' }] }, status: 422
        end
      else
        render json: { errors: [{ status: 401, title: 'Not authorized!' }] }, status: 401
      end
    end

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
