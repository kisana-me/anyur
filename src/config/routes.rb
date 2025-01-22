Rails.application.routes.draw do
  root "pages#index"
  
  get "terms" => "pages#terms"
  get "privacy" => "pages#privacy"
  get "contact" => "pages#contact"
  
  get "up" => "rails/health#show", as: :rails_health_check
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
