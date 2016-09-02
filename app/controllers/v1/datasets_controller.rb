module V1
  class DatasetsController < ApplicationController
    before_action :set_dataset,      except: [:index, :create, :info]
    before_action :populate_dataset, only: :show, if: :params_includes_present?

    def index
      @datasets = Connector.fetch_all(options_filter)
      render json: @datasets, each_serializer: DatasetSerializer, root: false
    end

    def show
      render json: @dataset, serializer: DatasetSerializer, root: false, meta: { status: @dataset.try(:status_txt),
                                                                                 overwrite: @dataset.try(:data_overwrite),
                                                                                 updated_at: @dataset.try(:updated_at),
                                                                                 created_at: @dataset.try(:created_at) }
    end

    def update
      if @dateable.update(dataset_params_for_update)
        render json: @dataset.reload, status: 200, serializer: DatasetSerializer, root: false
      else
        render json: { success: false, message: 'Error creating dataset' }, status: 422
      end
    end

    def update_data
      begin
        @dateable.connect_to_service(dataset_data_params_for_update)
        render json: { success: true, message: 'Dataset data update in progress' }, status: 200
      rescue
        render json: { success: false, message: 'Error updating dataset data' }, status: 422
      end
    end

    def overwrite_data
      begin
        if @dataset.data_overwrite? && @json_connector
          @dateable.connect_to_service(dataset_data_params_for_overwrite)
          render json: { success: true, message: 'Dataset data update in progress' }, status: 200
        elsif @json_connector
          render json: { errors: [{ status: 422, title: "Dataset data is locked and can't be updated" }] }, status: 422
        else
          render json: { errors: [{ status: 422, title: 'Not a fuction' }] }, status: 422
        end
      rescue
        render json: { errors: [{ status: 422, title: 'Error updating dataset data' }] }, status: 422
      end
    end

    def update_layer_info
      begin
        @dataset.update_layer_info(params.to_unsafe_hash)
        render json: { success: true, message: 'Dataset layer info update in progress' }, status: 200
      rescue
        render json: { success: false, message: 'Error updating dataset data' }, status: 422
      end
    end

    def delete_data
      begin
        @dateable.connect_to_service(dataset_data_params_for_delete)
        render json: { success: true, message: 'Dataset data deleted' }, status: 200
      rescue
        render json: { success: false, message: 'Error deleting dataset data' }, status: 422
      end
    end

    def create
      @dateable = Connector.new(dataset_params)
      if @dateable.save
        @dateable.connect_to_service(dataset_params)
        render json: @dateable.dataset, status: 201, serializer: DatasetSerializer, root: false
      else
        render json: { success: false, message: 'Error creating dataset' }, status: 422
      end
    end

    def clone
      @dataset = clone_dataset.dataset
      if @dataset && @dataset.save
        @dataset.dateable.connect_to_service(dataset_params)
        render json: @dataset, status: 201, serializer: DatasetSerializer, root: false
      else
        render json: { success: false, message: 'Error cloning dataset' }, status: 422
      end
    end

    def destroy
      if @dataset.deleted?
        render json: { success: true, message: 'Dataset deleted!' }, status: 200
      else
        @dateable.connect_to_service('delete')
        render json: { success: true, message: 'Dataset would be deleted!' }, status: 200
      end
    end

    private

      def clone_dataset
        dataset_params['dataset_url'] = dataset_url_fixer
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
            row_count: @dataset.attributes['row_count']
          }
        ) if dataset_params['dataset_url'].present?
      end

      def dataset_url_fixer
        dataset_params['dataset_url'].include?('http://') ? dataset_params['dataset_url'] : "#{ServiceSetting.gateway_url}#{dataset_params['dataset_url']}"
      end

      def options_filter
        params.permit(:connector_type, :status, :dataset, :app, :includes, dataset: {})
      end

      def set_dataset
        @dataset        = Dataset.includes(:dateable).find(params[:id])
        @dateable       = @dataset.dateable
        @json_connector = @dateable.class.name.include?('JsonConnector')
      end

      def populate_dataset
        @dataset.populate(options_filter['includes'], options_filter['app'])
      end

      def dataset_params
        params.require(:dataset).permit!
      end

      def params_includes_present?
        params[:includes].present?
      end

      def dataset_params_for_update
        if @json_connector
          params.require(:dataset).except(:data, :data_attributes, :connector_url).permit!
        else
          params.require(:dataset).except(:data, :data_attributes).permit!
        end
      end

      def dataset_data_params_for_update
        if @json_connector && params[:data_id].present?
          params.require(:dataset).merge(data_to_update: true, data_id: params[:data_id]).permit!
        else
          params.require(:dataset).merge(to_update: true).permit!
        end
      end

      def dataset_data_params_for_overwrite
        params.require(:dataset).merge(overwrite: true).permit! if @json_connector
      end

      def dataset_data_params_for_delete
        if @json_connector && params[:data_id].present?
          params.merge(to_delete: true, data_to_update: true, data_id: params[:data_id])
        end
      end
  end
end
