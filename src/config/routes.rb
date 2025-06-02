Rails.application.routes.draw do
  root "pages#index"
  get "home" => "pages#home"

  resources :documents, param: :name_id, only: %i[ index show ]
  resources :services, param: :name_id, only: %i[ index show ]
  # resources :personas, except: %i[ index show ]
  resources :inquiries, only: %i[ new create ]

  # oauth
  get "oauth/authorize" => "oauth#authorize"
  post "oauth/authorize" => "oauth#post_authorize"
  post "oauth/token" => "oauth#token"

  # pages
  get "terms-of-service" => "pages#terms_of_service"
  get "privacy-policy" => "pages#privacy_policy"
  get "contact" => "pages#contact"

  # signup
  get "signup" => "signup#index"
  post "signup/1" => "signup#page_1"
  post "signup/2" => "signup#page_2"

  # verify email
  get "verify-email" => "verify_email#index"
  get "verify-email/change" => "verify_email#change"
  patch "verify-email/change" => "verify_email#post_change"
  get "verify-email/code" => "verify_email#code"
  post "verify-email/code" => "verify_email#post_code"

  # sessions
  get "signin" => "sessions#signin"
  post "signin" => "sessions#post_signin"
  delete "signout" => "sessions#signout"

  # accounts
  get "account" => "accounts#show"
  get "account/change" => "accounts#index"
  post "account/change" => "accounts#change"
  get "account/edit" => "accounts#edit"
  patch "account/edit" => "accounts#update"
  get "account/delete" => "accounts#delete"
  delete "account/delete/confirm" => "accounts#delete_confirm"
  get "account/email/edit" => "accounts#edit_email"
  post "account/email/check" => "accounts#check_email"
  patch "account/email/update" => "accounts#update_email"
  get "account/password/edit" => "accounts#edit_password"
  patch "account/password/update" => "accounts#update_password"

  # subscription
  resources :subscriptions, only: [:index, :new, :create] do
    collection do
      get "success"
      get "cancel"
      get "customer_portal"
      post "change"
    end
  end

  # Stripe
  post "stripe/webhooks", to: "stripe_webhooks#create"

  # reset password
  get "account/reset-password" => "reset_password#get_request"
  post "account/reset-password" => "reset_password#post_request"
  get "account/reset-password/edit" => "reset_password#edit"
  patch "account/reset-password/update" => "reset_password#update"

  # api
  namespace :api do
    root "resources#root"
    post "resources" => "resources#index"
  end

  # admin
  namespace :admin do
    root "pages#index"
    get "test" => "pages#test"
    resources :documents
    resources :services do
      member do
        post "create_client_secret"
      end
    end
    resources :personas, only: %i[ index ]
    resources :inquiries, only: %i[ index ]
  end

  # others
  # get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest, defaults: { format: :json }
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # errors
  unless Rails.env.development?
    get "*path", to: "application#render_404"
    post "*path", to: "application#render_404"
    put "*path", to: "application#render_404"
    patch "*path", to: "application#render_404"
    delete "*path", to: "application#render_404"
    match "*path", to: "application#render_404", via: :options
  end
end
