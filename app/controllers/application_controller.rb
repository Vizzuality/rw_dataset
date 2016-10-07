# frozen_string_literal: true
class ApplicationController < ActionController::API
  before_action :deep_underscore_params!

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  protected

    def record_not_found
      render json: { errors: [{ status: '404', title: 'Record not found' }] } ,  status: 404
    end

    def deep_underscore_params!(val = request.parameters)
      case val
      when Array then val.map { |v| deep_underscore_params!(v) }
      when Hash
        val.keys.each do |k, v = val[k]|
          val.delete k
          val[k.underscore] = deep_underscore_params!(v)
        end
        val
      else
        val
      end
    end
end
