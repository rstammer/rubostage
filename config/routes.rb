Rails.application.routes.draw do
  get "up" => "rails/health#show", :as => :rails_health_check

  root "songs#index"

  resources :songs, only: [:index, :create, :show] do
    resource :playback, only: :create
  end
  resource :playback, only: :destroy
end
