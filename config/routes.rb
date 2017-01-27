# frozen_string_literal: true
Rails.application.routes.draw do
  scope module: :v1, constraints: APIVersion.new(version: 1, current: true) do
    resources :datasets, path: 'dataset', only: [:index, :show, :update, :create, :destroy]
    post   'dataset/:id/clone',           to: 'datasets#clone'
    post   'dataset/:id/data',            to: 'datasets#update_data'    # concat move to adapter (csv - json)
    post   'dataset/:id/data-overwrite',  to: 'datasets#overwrite_data' # move to adapter (csv - json)
    post   'dataset/:id/data/(:data_id)', to: 'datasets#update_data'    # move to json
    delete 'dataset/:id/data/(:data_id)', to: 'datasets#delete_data'    # move to json

    get 'info', to: 'info#info'
    get 'ping', to: 'info#ping'
  end
end
