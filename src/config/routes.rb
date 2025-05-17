Rails.application.routes.draw do
  root "pages#index"

  resources :services

  resources :profiles

  resources :documents

  # signup
  get "signup" => "signup#index"
  post "signup/1" => "signup#page_1"
  post "signup/2" => "signup#page_2"

  # sessions
  get "signin" => "sessions#signin"
  post "signin" => "sessions#post_signin"
  delete 'signout' => 'sessions#signout'

  # accounts
  get "accounts" => "accounts#index"
  post "accounts/change" => "accounts#change"
  get "accounts/current" => "accounts#show", as: :current_account
  get "accounts/current/edit" => "accounts#edit", as: :edit_account
  patch "accounts/current/edit" => "accounts#update", as: :update_account
  delete 'accounts/current/delete' => 'accounts#destroy', as: :delete_account

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

  # errors
  get '*path', to: 'errors#not_found'
  post '*path', to: 'errors#not_found'
  put '*path', to: 'errors#not_found'
  patch '*path', to: 'errors#not_found'
  delete '*path', to: 'errors#not_found'
  match '*path', to: 'errors#not_found', via: :options
end
