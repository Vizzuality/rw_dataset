# frozen_string_literal: true
module V1
  class DatasetsController < ApplicationController
    include ParamsHandler

    before_action :set_dataset,           except: [:index, :create, :info]
    before_action :populate_dataset,      only: :show, if: :params_includes_present?
    before_action :sanitize_params,       only: :index
    before_action :reject_corrupt_params, only: [:update, :create]

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
      begin
        if @dateable.update(dataset_params_for_update)
          render json: @dataset.reload, status: 200, serializer: DatasetSerializer, meta: { status: @dataset.try(:status_txt),
                                                                                            overwrite: @dataset.try(:data_overwrite),
                                                                                            updated_at: @dataset.try(:updated_at),
                                                                                            created_at: @dataset.try(:created_at) }
        else
          render json: { errors: [{ status: 422, title: @dateable.errors.full_messages }] }, status: 422
        end
      rescue StandardError => e
        render json: { errors: [{ status: 422, title: e }] }, status: 422
      end
    end

    def create
      begin
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
      rescue StandardError => e
        render json: { errors: [{ status: 422, title: e }] }, status: 422
      end
    end

    def destroy
      if @dataset.deleted?
        render json: { success: true, message: 'Dataset deleted!' }, status: 200
      else
        if @dateable.connector_provider.include?('cartodb')
          @dateable.destroy
          render json: { success: true, message: 'Dataset deleted!' }, status: 200
        else
          @dateable.connect_to_service('delete')
          render json: { success: true, message: 'Dataset would be deleted!' }, status: 200
        end
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

      def sanitize_params
        params['ids'] = params['ids'].split(',').select { |id| /^[a-z0-9]+[-a-z0-9]*[a-z0-9]+$/i.match(id) } if params['ids'].present?
      end

      def dataset_params
        dataset_params_sanitizer.except(:user_id).tap do |create_params|
          create_params[:dataset_attributes][:user_id] = params.dig(:logged_user, :id)
        end
      end

      def dataset_params_for_update
        if @json_connector
          dataset_params_sanitizer.except(:data, :data_attributes, :logged_user, :connector_url, :user_id).tap do |update_params|
            update_params[:dataset_attributes][:user_id] = params[:dataset][:user_id] if params[:dataset][:user_id].present? && params[:logged_user][:role] == 'superadmin'
          end
        elsif @doc_connector
          dataset_params_sanitizer.except(:point, :polygon, :logged_user, :user_id).tap do |update_params|
            update_params[:dataset_attributes][:user_id] = params[:dataset][:user_id] if params[:dataset][:user_id].present? && params[:logged_user][:role] == 'superadmin'
          end
        else
          dataset_params_sanitizer.except(:data, :data_attributes, :logged_user, :user_id).tap do |update_params|
            update_params[:dataset_attributes][:user_id] = params[:dataset][:user_id] if params[:dataset][:user_id].present? && params[:logged_user][:role] == 'superadmin'
          end
        end
      end

      def reject_corrupt_params
        if params[:dataset].present? && params[:dataset][:dataset_attributes].present?
          render json: { errors: [{ status: 422, title: 'The attribute dataset_attributes is not valid' }] }, status: 422
        elsif params[:dataset].blank? || params[:name].present? ||
              params[:connector_url].present? || params[:data].present? ||
              params[:table_name].present? || params[:connector_type] || params[:provider].present?
          render json: { errors: [{ status: 422, title: 'The attribute dataset is not present' }] }, status: 422
        end
      end
  end
end
