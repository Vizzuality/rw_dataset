# frozen_string_literal: true
Rails.application.routes.draw do
  scope module: :v1, constraints: APIVersion.new(version: 1, current: true) do
    resources :datasets, only: [:index, :show, :update, :create, :destroy]
    post   'datasets/:id/clone',           to: 'datasets#clone'
    post   'datasets/:id/data',            to: 'datasets#update_data'
    post   'datasets/:id/data-overwrite',  to: 'datasets#overwrite_data'
    post   'datasets/:id/data/(:data_id)', to: 'datasets#update_data'
    delete 'datasets/:id/data/(:data_id)', to: 'datasets#delete_data'
    put    'datasets/:id/layer',           to: 'datasets#update_layer_info'

    get 'info', to: 'info#info'
    get 'ping', to: 'info#ping'
  end
end
