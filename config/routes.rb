# frozen_string_literal: true
Rails.application.routes.draw do
  scope module: :v1, constraints: APIVersion.new(version: 1, current: true) do
    resources :datasets, path: 'dataset', only: [:index, :show, :update, :create, :destroy]
    post   'dataset/:id/clone',           to: 'datasets#clone'
    post   'dataset/:id/data',            to: 'datasets#update_data'
    post   'dataset/:id/data-overwrite',  to: 'datasets#overwrite_data'
    post   'dataset/:id/data/(:data_id)', to: 'datasets#update_data'
    delete 'dataset/:id/data/(:data_id)', to: 'datasets#delete_data'
    put    'dataset/:id/layer',           to: 'datasets#update_layer_info'

    get 'info', to: 'info#info'
    get 'ping', to: 'info#ping'
  end
end
