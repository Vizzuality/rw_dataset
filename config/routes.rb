Rails.application.routes.draw do
  scope module: :v1, constraints: APIVersion.new(version: 1, current: true) do
    resources :datasets, only: [:index, :show, :update, :create, :destroy]
    post 'datasets/:id/clone', to: 'datasets#clone'
  end
end
