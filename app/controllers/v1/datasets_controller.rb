# frozen_string_literal: true
module V1
  class DatasetsController < ApplicationController
    before_action :set_dataset,      except: [:index, :create, :info]
    before_action :populate_dataset, only: :show, if: :params_includes_present?
    before_action :set_user,         except: [:index, :show]
    before_action :set_caller,       only: :update

    include ParamsHandler

    def index
      @datasets = Connector.fetch_all(options_filter)
      render json: @datasets, each_serializer: DatasetSerializer, include: params[:includes], meta: { datasets_count: @datasets.size }
    end

    def show
      render json: @dataset, serializer: DatasetSerializer, include: params[:includes], meta: { status: @dataset.try(:status_txt),
                                                                                                overwrite: @dataset.try(:data_overwrite),
                                                                                                updated_at: @dataset.try(:updated_at),
                                                                                                created_at: @dataset.try(:created_at) }
    end

    def update
      if @authorized.present?
        if @dateable.update(@dataset_params_for_update)
          render json: @dataset.reload, status: 200, serializer: DatasetSerializer, meta: { status: @dataset.try(:status_txt),
                                                                                            overwrite: @dataset.try(:data_overwrite),
                                                                                            updated_at: @dataset.try(:updated_at),
                                                                                            created_at: @dataset.try(:created_at) }
        else
          render json: { errors: [{ status: 422, title: 'Error updating dataset' }] }, status: 422
        end
      else
        render json: { errors: [{ status: 401, title: 'Not authorized!' }] }, status: 401
      end
    end

    def update_data
      authorized = User.authorize_user!(@user, intersect_apps(@dataset.application, @apps, @dataset_apps), @dataset.user_id, match_apps: true)
      if authorized.present?
        begin
          @dateable.connect_to_service(dataset_data_params_for_update)
          render json: { success: true, message: 'Dataset data update in progress' }, status: 200
        rescue
          render json: { success: false, message: 'Error updating dataset data' }, status: 422
        end
      else
        render json: { errors: [{ status: 401, title: 'Not authorized!' }] }, status: 401
      end
    end

    def overwrite_data
      authorized = User.authorize_user!(@user, intersect_apps(@dataset.application, @apps, @dataset_apps), @dataset.user_id, match_apps: true)
      if authorized.present?
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
      else
        render json: { errors: [{ status: 401, title: 'Not authorized!' }] }, status: 401
      end
    end

    def update_layer_info
      authorized = User.authorize_user!(@user, intersect_apps(@dataset.application, @apps, @dataset_apps), @dataset.user_id, match_apps: true)
      if authorized.present?
        begin
          @dataset.update_layer_info(params.to_unsafe_hash)
          render json: { success: true, message: 'Dataset layer info update in progress' }, status: 200
        rescue
          render json: { success: false, message: 'Error updating dataset data' }, status: 422
        end
      else
        render json: { errors: [{ status: 401, title: 'Not authorized!' }] }, status: 401
      end
    end

    def delete_data
      authorized = User.authorize_user!(@user, intersect_apps(@dataset.application, @apps, @dataset_apps), @dataset.user_id, match_apps: true)
      if authorized.present?
        begin
          @dateable.connect_to_service(dataset_data_params_for_delete)
          render json: { success: true, message: 'Dataset data deleted' }, status: 200
        rescue
          render json: { success: false, message: 'Error deleting dataset data' }, status: 422
        end
      else
        render json: { errors: [{ status: 401, title: 'Not authorized!' }] }, status: 401
      end
    end

    def create
      authorized = User.authorize_user!(@user, @dataset_apps)
      if authorized.present?
        @dateable = Connector.new(dataset_params)
        if @dateable.save
          @dateable.connect_to_service(dataset_params)
          render json: @dateable.dataset, status: 201, serializer: DatasetSerializer, meta: { status: @dataset.try(:status_txt),
                                                                                              overwrite: @dataset.try(:data_overwrite),
                                                                                              updated_at: @dataset.try(:updated_at),
                                                                                              created_at: @dataset.try(:created_at) }
        else
          render json: { success: false, message: 'Error creating dataset' }, status: 422
        end
      else
        render json: { errors: [{ status: 401, title: 'Not authorized!' }] }, status: 401
      end
    end

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
          render json: { success: false, message: 'Error cloning dataset' }, status: 422
        end
      else
        render json: { errors: [{ status: 401, title: 'Not authorized!' }] }, status: 401
      end
    end

    def destroy
      authorized = User.authorize_user!(@user, intersect_apps(@dataset.application, @apps, @dataset_apps), @dataset.user_id, match_apps: true)
      if authorized.present?
        if @dataset.deleted?
          render json: { success: true, message: 'Dataset deleted!' }, status: 200
        else
          @dateable.connect_to_service('delete')
          render json: { success: true, message: 'Dataset would be deleted!' }, status: 200
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

      def options_filter
        params.permit(:connector_type, :status, :dataset, :app, :includes, dataset: {})
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

      def set_user
        if ENV.key?('OLD_GATEWAY') && ENV.fetch('OLD_GATEWAY').include?('true')
          User.data = [{ user_id: '123-123-123', role: 'superadmin', apps: nil }]
          @user= User.last
        elsif dataset_params[:logged_user].present? && dataset_params[:logged_user][:id] != 'microservice'
          user_id       = dataset_params[:logged_user][:id]
          @role         = dataset_params[:logged_user][:role].downcase
          @apps         = if dataset_params[:logged_user][:extra_user_data].present? && dataset_params[:logged_user][:extra_user_data][:apps].present?
                            dataset_params[:logged_user][:extra_user_data][:apps].map { |v| v.downcase }.uniq
                          end
          @dataset_apps = dataset_params[:dataset_attributes][:application]

          User.data = [{ user_id: user_id, role: @role, apps: @apps }]
          @user= User.last
        else
          render json: { errors: [{ status: 401, title: 'Not authorized!' }] }, status: 401 if dataset_params[:logged_user][:id] != 'microservice'
        end
      end

      def set_caller
        if dataset_params[:logged_user].present? && dataset_params[:logged_user][:id] == 'microservice'
          @dataset_params_for_update = dataset_params_for_update.each { |k,v| v.delete('user_id') if k == 'dataset_attributes' }
          @authorized = true
        else
          @dataset_params_for_update = dataset_params_for_update
          @authorized = User.authorize_user!(@user, intersect_apps(@dataset.application, @apps, @dataset_apps), @dataset.user_id, match_apps: true)
        end
      end

      def intersect_apps(dataset_apps, user_apps, additional_apps=nil)
        if additional_apps.present?
          if (dataset_apps | additional_apps).uniq.sort == (user_apps & (dataset_apps | additional_apps)).uniq.sort
            dataset_apps | additional_apps
          else
            ['apps_not_authorized'] if dataset_params[:logged_user][:id] != 'microservice'
          end
        else
          dataset_apps
        end
      end

      def params_includes_present?
        params[:includes].present?
      end

      def dataset_params
        dataset_params_sanitizer
      end

      def dataset_params_for_update
        if @json_connector
          dataset_params_sanitizer.except(:data, :data_attributes, :logged_user, :connector_url, :connector_type, :connector_provider)
        elsif @doc_connector
          dataset_params_sanitizer.except(:point, :polygon, :logged_user, :connector_type, :connector_provider)
        else
          dataset_params_sanitizer.except(:data, :data_attributes, :logged_user, :connector_type, :connector_provider)
        end
      end

      def dataset_data_params_for_update
        if @json_connector && params[:data_id].present?
          params.require(:dataset).merge(data_to_update: true, data_id: params[:data_id], logged_user: params[:logged_user]).permit!
        else
          params.require(:dataset).merge(to_update: true, logged_user: params[:logged_user]).permit!
        end
      end

      def dataset_data_params_for_overwrite
        params.require(:dataset).merge(overwrite: true, logged_user: params[:logged_user]).permit! if @overwriteable
      end

      def dataset_data_params_for_delete
        if @json_connector && params[:data_id].present?
          params.merge(to_delete: true, data_to_update: true, data_id: params[:data_id], logged_user: params[:logged_user])
        end
      end
  end
end
