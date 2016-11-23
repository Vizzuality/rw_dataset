# frozen_string_literal: true
module V1
  class DatasetsController < ApplicationController
    include ParamsHandler

    before_action :set_dataset,      except: [:index, :create, :info]
    before_action :populate_dataset, only: :show, if: :params_includes_present?

    include Authorization
    include Clone

    def index
      datasets_index = DatasetsIndex.new(self)
      render json: datasets_index.datasets, each_serializer: DatasetSerializer, include: params[:includes], links: datasets_index.links, type: 'dataset'
    end

    def show
      render json: @dataset, serializer: DatasetSerializer, include: params[:includes], meta: { status: @dataset.try(:status_txt),
                                                                                                overwrite: @dataset.try(:data_overwrite),
                                                                                                updated_at: @dataset.try(:updated_at),
                                                                                                created_at: @dataset.try(:created_at) }
    end

    def update
      if @dateable.update(@dataset_params_for_update)
        render json: @dataset.reload, status: 200, serializer: DatasetSerializer, meta: { status: @dataset.try(:status_txt),
                                                                                          overwrite: @dataset.try(:data_overwrite),
                                                                                          updated_at: @dataset.try(:updated_at),
                                                                                          created_at: @dataset.try(:created_at) }
      else
        render json: { errors: [{ status: 422, title: @dateable.errors.full_messages }] }, status: 422
      end
    end

    def update_data
      begin
        @dateable.connect_to_service(dataset_data_params_for_update)
        render json: { success: true, message: 'Dataset data update in progress' }, status: 200
      rescue
        render json: { errors: [{ status: 422, title: 'Error updating dataset data' }] }, status: 422
      end
    end

    def overwrite_data
      begin
        if @dataset.data_overwrite? && @overwriteable
          if @dateable.update(dataset_params_for_update)
            @dateable.connect_to_service(dataset_data_params_for_overwrite)
            render json: { success: true, message: 'Dataset data update in progress' }, status: 200
          else
            render json: { errors: [{ status: 422, title: 'Error updating dataset data' }] }, status: 422
          end
        elsif @overwriteable
          render json: { errors: [{ status: 422, title: "Dataset data is locked and can't be updated" }] }, status: 422
        else
          render json: { errors: [{ status: 422, title: 'Not a fuction' }] }, status: 422
        end
      rescue
        render json: { errors: [{ status: 422, title: 'Error updating dataset data' }] }, status: 422
      end
    end

    def delete_data
      begin
        @dateable.connect_to_service(dataset_data_params_for_delete)
        render json: { success: true, message: 'Dataset data deleted' }, status: 200
      rescue
        render json: { errors: [{ status: 422, title: 'Error updating dataset data' }] }, status: 422
      end
    end

    def create
      @dateable = Connector.new(dataset_params)
      if @dateable.save
        @dateable.connect_to_service(dataset_params)
        render json: @dateable.dataset, status: 201, serializer: DatasetSerializer, meta: { status: @dataset.try(:status_txt),
                                                                                            overwrite: @dataset.try(:data_overwrite),
                                                                                            updated_at: @dataset.try(:updated_at),
                                                                                            created_at: @dataset.try(:created_at) }
      else
        render json: { errors: [{ status: 422, title: @dateable.errors.full_messages }] }, status: 422
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

    def clone
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
    end

    private

      def options_filter
        params.permit(:connector_type, :provider, :status, :dataset, :app, :includes, dataset: {})
      end

      def set_dataset
        @dataset        = Dataset.includes(:dateable).find(params[:id])
        @dateable       = @dataset.dateable                                          if @dataset.present?
        @json_connector = @dateable.class.name.include?('JsonConnector')             if @dateable.present?
        @doc_connector  = @dateable.class.name.include?('DocConnector')              if @dateable.present?
        @overwriteable  = @dateable.class.name.in? ['JsonConnector', 'DocConnector'] if @dateable.present?
        record_not_found                                                             if @dataset.blank?
      end

      def populate_dataset
        @dataset.populate(options_filter['includes'], options_filter['app'])
      end

      def params_includes_present?
        params[:includes].present?
      end
  end
end
