module V1
  class DatasetsController < ApplicationController
    before_action :set_dataset, except: [:index, :create]

    def index
      @datasets = Connector.fetch_all(connector_type_filter)
      render json: @datasets, each_serializer: DatasetArraySerializer, root: false
    end

    def show
      render json: @dataset, serializer: DatasetSerializer, root: false
    end

    def update
      if @dataset.dateable.update(dataset_params)
        render json: @dataset, status: 201, serializer: DatasetSerializer, root: false
      else
        render json: { success: false, message: 'Error creating dataset' }, status: 422
      end
    end

    def create
      @dataset = Connector.new(dataset_params)
      if @dataset.save
        build_dataset
        render json: @dataset.dataset, status: 201, serializer: DatasetSerializer, root: false
      else
        render json: { success: false, message: 'Error creating dataset' }, status: 422
      end
    end

    def clone
      @connector_attributes = @dataset.dateable.attributes
      @connector = build_connector
      @dataset   = clone_dataset
      if @dataset && @dataset.save
        render json: @dataset, status: 201, serializer: DatasetSerializer, root: false
      else
        render json: { success: false, message: 'Error cloning dataset' }, status: 422
      end
    end

    def destroy
      @dataset.dateable.destroy
      @dataset.destroy
      begin
        render json: { message: 'Dataset deleted' }, status: 200
      rescue ActiveRecord::RecordNotDestroyed
        return render json: @dataset.erors, message: 'Dataset could not be deleted', status: 422
      end
    end

    private

      def build_dataset
        return if dataset_params['connector_type'].present? && dataset_params['connector_type'].include?('json')
        Dataset.create(dataset_params['dataset_attributes'])
      end

      def build_connector
        JsonConnector.create(
          connector_name: @connector_attributes['connector_name'] + '_copy',
          connector_path: @connector_attributes['connector_path'],
          attributes_path: @connector_attributes['attributes_path'],
          parent_connector_url: dataset_params['dataset_url'],
          parent_connector_provider: @connector_attributes['connector_provider'],
          parent_connector_type: @dataset.dateable.class.name,
          parent_connector_id: @dataset.attributes['id']
        ) if dataset_params['dataset_url'].present?
      end

      def clone_dataset
        Dataset.new(
          dateable_type: 'JsonConnector',
          dateable_id: @connector.id,
          data_columns: @dataset.attributes['data_columns'],
          data: ConnectorService.connect_to_provider(dataset_params['dataset_url'], 'data')
        ) if dataset_params['dataset_url'].present?
      end

      def connector_type_filter
        params.permit(:connector_type)
      end

      def set_dataset
        @dataset = Dataset.find(params[:id])
      end

      def dataset_params
        params.require(:dataset).permit!
      end
  end
end
