Rails.application.routes.draw do
  root "pages#index"

  # signup
  get "signup" => "signup#index", as: :signup
  get "signup/1" => "signup#form_1", as: :signup_form_1
  post "signup/1" => "signup#check_1", as: :signup_check_1
  get "signup/confirm" => "signup#form_confirm", as: :signup_form_confirm
  post "signup/confirm" => "signup#check_confirm", as: :signup_check_confirm

  # sessions
  get "signin" => "sessions#signin_form", as: :signin_form
  post "signin" => "sessions#signin", as: :signin
  delete 'signout' => 'sessions#signout', as: :signout

  # accounts
  resources :accounts, except: %i[index]

  # documents
  namespace :docs do
  end

  # pages
  get "terms-of-service" => "pages#terms_of_service"
  get "privacy-policy" => "pages#privacy_policy"
  get "contact" => "pages#contact"

  # others
  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
