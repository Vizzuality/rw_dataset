Rails.application.routes.draw do
  scope module: :v1, constraints: APIVersion.new(version: 1, current: true) do
    resources :datasets, only: [:index, :show, :update, :create, :destroy]
  end
end
