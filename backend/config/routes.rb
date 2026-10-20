require "sidekiq/web"

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      scope :guest, module: :guest_portal, as: :guest do
        resource :session, only: :create
        resource :reservation, only: :show
        resource :check_in, only: :create
      end

      namespace :staff do
        resources :arrivals, only: :index
        resources :check_ins, only: [] do
          post :retry, on: :member
        end
        resources :integration_events, only: :index
      end
    end
  end

  mount Sidekiq::Web => "/sidekiq"
end
