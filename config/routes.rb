Rails.application.routes.draw do
  get 'password_resets/new'
  get 'password_resets/edit'
  root   'static_pages#home'
  get    '/faq',    to: 'static_pages#faq'
  get    '/contact', to: 'static_pages#contact'
  get    '/overview', to: 'static_pages#overview'
  get    '/about',    to: 'static_pages#about'
  post   '/contact',  to: 'static_pages#create'
  get    '/message-confirmation', to: 'static_pages#message_confirmation'
  get '/javascript-warning', to: 'static_pages#javascript'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'
  resources :users
  get 'api/query_user',             to: 'api_endpoint#query_user'
  get 'api/query_vehicle',          to: 'api_endpoint#query_vehicle'
  post 'api/save_order_status',     to: 'api_endpoint#save_order_status'
  resources :vehicles
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :checkouts,           only: [:new, :create, :destroy]
  resources :payments,            only: [:new, :create]
  resources :returns,             only: [:index, :new, :create]
  get '/get_models_by_make',          to: 'vehicles#get_models_by_make'
  get '/get_years_by_model',          to: 'vehicles#get_years_by_model'
  get '/checkouts/success(/:id)',     to: 'payments#success'
  get '/setup',                       to: 'payments#setup'
  post '/create-customer',            to: 'payments#create_customer'
  post '/create-subscription',        to: 'payments#create_subscription'
  post '/retrieve-customer-payment-method', to: 'payments#retrieve_customer_payment_method'
  get  '/subscription-complete(/:id)', to: 'payments#subscription_complete'
  post '/webhook',             to: 'webhook#stripe_webhook'
end