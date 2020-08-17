Rails.application.routes.draw do
  get 'password_resets/new'
  get 'password_resets/edit'
  root   'static_pages#home'
  get    '/help',    to: 'static_pages#help'
  get    '/about',   to: 'static_pages#about'
  get    '/contact', to: 'static_pages#contact'
  get '/javascript-warning', to: 'static_pages#javascript'
  get    '/signup',  to: 'users#new'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'
  resources :users
  resources :vehicles
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :checkouts,           only: [:index, :create]
  get '/get_models_by_make',          to: 'vehicles#get_models_by_make'
  get '/get_years_by_model',          to: 'vehicles#get_years_by_model'
  get '/checkouts/success',           to: 'checkouts#success'
  get '/setup',                       to: 'checkouts#setup'
  post '/create-customer',            to: 'checkouts#create_customer'
  post '/create-subscription',        to: 'checkouts#create_subscription'
  post '/retrieve-customer-payment-method', to: 'checkouts#retrieve_customer_payment_method'
  get '/subscription-complete',       to: 'checkouts#subscription_complete'
  post '/stripe-webhook',             to: 'checkouts#stripe_webhook'
end