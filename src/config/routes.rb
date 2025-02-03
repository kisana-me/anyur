Rails.application.routes.draw do
  root "pages#index"
  
  get "terms" => "pages#terms"
  get "privacy" => "pages#privacy"
  get "contact" => "pages#contact"

  get "login" => "pages#login"
  post "login" => "pages#post_login"
  resources :accounts, except: %i[index]
  
  get "up" => "rails/health#show", as: :rails_health_check

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
