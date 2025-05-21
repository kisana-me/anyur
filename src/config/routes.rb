Rails.application.routes.draw do
  root "pages#index"
  get "home" => "pages#home"

  resources :services, only: %i[ index show ]

  resources :personas

  resources :documents, param: :name_id, only: %i[ index show ]

  # signup
  get "signup" => "signup#index"
  post "signup/1" => "signup#page_1"
  post "signup/2" => "signup#page_2"

  # sessions
  get "signin" => "sessions#signin"
  post "signin" => "sessions#post_signin"
  delete 'signout' => 'sessions#signout'

  # accounts
  # get "accounts" => "accounts#index"
  get "account" => "accounts#show"
  get "account/change" => "accounts#index"
  post "account/change" => "accounts#change"
  get "account/edit" => "accounts#edit"
  patch "account/edit" => "accounts#update"
  get "account/delete" => "accounts#delete"
  delete "account/delete/confirm" => "accounts#delete_confirm"
  get "account/verify-email" => "accounts#verify_email"
  post "account/verify-email" => "accounts#post_verify_email"
  get "account/email/edit" => "accounts#edit_email"
  patch "account/email/update" => "accounts#update_email"
  get "account/password/reset" => "accounts#request_reset_password"
  post "account/password/reset" => "accounts#post_request_reset_password"
  get "account/password/edit" => "accounts#edit_password"
  patch "account/password/update" => "accounts#update_password"

  # pages
  get "terms-of-service" => "pages#terms_of_service"
  get "privacy-policy" => "pages#privacy_policy"
  get "contact" => "pages#contact"
  # post "contact" => "pages#contact" # 受け取り

  # admin
  namespace :admin do
    root "pages#index"
    get "test" => "pages#test"
    resources :documents
  end

  # others
  # get "up" => "rails/health#show", as: :rails_health_check
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # errors
  get '*path', to: 'errors#not_found'
  post '*path', to: 'errors#not_found'
  put '*path', to: 'errors#not_found'
  patch '*path', to: 'errors#not_found'
  delete '*path', to: 'errors#not_found'
  match '*path', to: 'errors#not_found', via: :options
end
