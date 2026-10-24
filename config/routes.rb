Rails.application.routes.draw do
  get "up" => "rails/health#show", :as => :rails_health_check

  root "songs#index"

  resources :songs, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
    resource :playback, only: :create
    resource :command, only: :create
    resource :loop, only: :update
    resource :arrangement, only: :create
    resource :code, only: :create
    resource :recording, only: [:create, :show]
    resources :messages, only: :create, controller: "song_messages"
  end
  resource :playback, only: :destroy
  resource :sonic_pi, only: :create, controller: "sonic_pi"
  resource :controls, only: :show
  resource :transport, only: :show
  resource :settings, only: [:show, :update]
end
