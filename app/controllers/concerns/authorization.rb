# frozen_string_literal: true
module Authorization
  extend ActiveSupport::Concern

  included do
    before_action :set_user,       except: [:index, :show]
    before_action :set_caller,     only: :update
    before_action :authorize_user, only: [:update_data, :overwrite_data, :delete_data, :destroy, :create, :clone]

    private

      def set_user
        if ENV.key?('OLD_GATEWAY') && ENV.fetch('OLD_GATEWAY').include?('true')
          User.data = [{ user_id: '123-123-123', role: 'superadmin', apps: nil }]
          @user= User.last
        elsif params[:logged_user].present? && params[:logged_user][:id] != 'microservice'
          user_id       = params[:logged_user][:id]
          @role         = params[:logged_user][:role].downcase
          @apps         = if @role.include?('superadmin')
                            ['AllApps']
                          elsif params[:logged_user][:extra_user_data].present? && params[:logged_user][:extra_user_data][:apps].present?
                            params[:logged_user][:extra_user_data][:apps].map { |v| v.downcase }.uniq
                          end
          @dataset_apps = if !['destroy', 'delete_data'].include?(action_name) && dataset_params[:dataset_attributes].present? && dataset_params[:dataset_attributes][:application].present?
                            dataset_params[:dataset_attributes][:application]
                          end

          User.data = [{ user_id: user_id, role: @role, apps: @apps }]
          @user = User.last
        else
          render json: { errors: [{ status: 401, title: 'Not authorized!' }] }, status: 401 if params[:logged_user][:id] != 'microservice'
        end
      end

      def set_caller
        if dataset_params[:logged_user].present? && dataset_params[:logged_user][:id] == 'microservice'
          @authorized = true
        else
          @authorized = User.authorize_user!(@user, intersect_apps(@dataset.application, @apps, @dataset_apps), @dataset.user_id, match_apps: true)
        end

        if @authorized.blank?
          render json: { errors: [{ status: 401, title: 'Not authorized!' }] }, status: 401
        elsif (dataset_params[:table_name].present? ||
               dataset_params[:connector_type].present? ||
               dataset_params[:connector_provider].present?) &&
               dataset_params[:logged_user].present? && dataset_params[:logged_user][:id] != 'microservice'

          render json: { errors: [{ status: 422, title: 'The attributes: tableName, connectorType and provider can not be changed' }] }, status: 422
        elsif params[:dataset][:user_id].present? && params[:logged_user][:role] != 'superadmin'
          render json: { errors: [{ status: 401, title: 'Not authorized to update UserId' }] }, status: 401
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

      def authorize_user
        @authorized = if ['create', 'clone'].include?(action_name)
                        User.authorize_user!(@user, @dataset_apps)
                      else
                        User.authorize_user!(@user, intersect_apps(@dataset.application, @apps), @dataset.user_id, match_apps: true)
                      end

        if @authorized.blank?
          render json: { errors: [{ status: 401, title: 'Not authorized!' }] }, status: 401
        end
      end
  end

  class_methods {}
end
