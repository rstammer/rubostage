Rails.application.routes.draw do
  get "up" => "rails/health#show", :as => :rails_health_check

  root "songs#index"

  resources :songs, only: [:index, :create, :show, :edit, :update] do
    resource :playback, only: :create
    resource :command, only: :create
    resource :export, only: :create
  end
  resource :playback, only: :destroy
  resource :sonic_pi, only: :create, controller: "sonic_pi"
  resource :controls, only: :show
end
