# frozen_string_literal: true
Rails.application.routes.draw do
  scope module: :v1, constraints: APIVersion.new(version: 1, current: true) do
    resources :datasets, path: 'dataset', only: [:index, :show, :update, :create, :destroy]
    post   'dataset/:id/clone',           to: 'datasets#clone'

    get 'info', to: 'info#info'
    get 'ping', to: 'info#ping'
  end
end
