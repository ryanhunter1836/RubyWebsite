Rails.application.routes.draw do
  get 'password_resets/new'
  get 'password_resets/edit'
  root   'static_pages#home'
  get    '/help',    to: 'static_pages#help'
  get    '/about',   to: 'static_pages#about'
  get    '/contact', to: 'static_pages#contact'
  get    '/signup',  to: 'users#new'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'
  resources :users
  resources :vehicles
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :shopping_carts,      only: [:create]
  get '/checkouts/success',  to: 'checkouts#success'
  get '/checkouts/cancelled',to: 'checkouts#cancelled'
  get '/get_models_by_make', to: 'vehicles#get_models_by_make'
  get '/get_years_by_model', to: 'vehicles#get_years_by_model'
  get   '/setup',   to: 'checkouts#setup'
  post  '/create-checkout-session', to: 'checkouts#create_checkout_session'
  post  '/webhook', to: 'checkouts#webhook'

end
