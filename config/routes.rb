Rails.application.routes.draw do
  get 'password_resets/new'
  get 'password_resets/edit'
  root   'static_pages#home'
  get    '/faq',    to: 'static_pages#faq'
  get    '/help',   to: 'static_pages#help'
  get    '/contact', to: 'static_pages#contact'
  get    '/overview', to: 'static_pages#overview'
  get    '/about',    to: 'static_pages#about'
  get '/javascript-warning', to: 'static_pages#javascript'
  get    '/signup',  to: 'users#new'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'
  resources :users
  resources :vehicles
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :checkouts,           only: [:new, :create]
  get '/get_models_by_make',          to: 'vehicles#get_models_by_make'
  get '/get_years_by_model',          to: 'vehicles#get_years_by_model'
  get '/checkouts/success(/:id)',     to: 'checkouts#success'
  get '/setup',                       to: 'checkouts#setup'
  post '/create-customer',            to: 'checkouts#create_customer'
  post '/create-subscription',        to: 'checkouts#create_subscription'
  post '/retrieve-customer-payment-method', to: 'checkouts#retrieve_customer_payment_method'
  get  '/subscription-complete(/:id)', to: 'checkouts#subscription_complete'
  post '/stripe-webhook',             to: 'checkouts#stripe_webhook'
end