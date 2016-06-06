module V1
  class DatasetsController < ApplicationController
    before_action :set_dataset, except: [:index, :create, :info]

    def index
      @datasets = Connector.fetch_all(connector_type_filter)
      render json: @datasets, each_serializer: DatasetArraySerializer, root: false
    end

    def show
      render json: @dataset, serializer: DatasetSerializer, root: false
    end

    def update
      if @dateable.update(dataset_params)
        render json: @dataset.reload, status: 200, serializer: DatasetSerializer, root: false
      else
        render json: { success: false, message: 'Error creating dataset' }, status: 422
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

    def info
      @docs = Oj.load(File.read('lib/files/service.json'))
      render json: @docs
    end

    private

      def clone_dataset
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

      def connector_type_filter
        params.permit(:connector_type, :status, :dataset)
      end

      def set_dataset
        @dataset  = Dataset.find(params[:id])
        @dateable = @dataset.dateable
      end

      def dataset_params
        params.require(:dataset).permit!
      end
  end
end
