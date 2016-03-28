module V1
  class DatasetsController < ApplicationController
    before_action :set_dataset, except: [:index, :create]

    def index
      @datasets = RestConnector.all
      render json: @datasets, each_serializer: DatasetArraySerializer, root: false
    end

    def show
      render json: @dataset, serializer: DatasetSerializer, root: false
    end

    def update
      if @dataset.update(dataset_params)
        render json: @dataset, status: 201, serializer: DatasetSerializer, root: false
      else
        render json: { success: false, message: 'Error creating dataset' }, status: 422
      end
    end

    def create
      @dataset = RestConnector.new(dataset_params)
      if @dataset.save
        render json: @dataset, status: 201, serializer: DatasetSerializer, root: false
      else
        render json: { success: false, message: 'Error creating dataset' }, status: 422
      end
    end

    def destroy
      @dataset.destroy
      begin
        render json: { message: 'Dataset deleted' }, status: 200
      rescue ActiveRecord::RecordNotDestroyed
        return render json: @dataset.erors, message: 'Dataset could not be deleted', status: 422
      end
    end

    private

      def set_dataset
        @dataset = RestConnector.find(params[:id])
      end

      def dataset_params
        params.require(:dataset).permit(:connector_name, :connector_url, :connector_format, :connector_path, :connector_provider, :connector_data, :attributes_path, connector_params_attributes: [:connector_id, :param_type, :key_name, :value], dataset_attributes: [:table_name]).tap do |whitelisted|
          # whitelisted[:connector_data] = params[:connector][:connector_data]
        end
      end
  end
end
