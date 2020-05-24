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
  resources :checkouts,           only: [:new, :create]
  get 'thankyou', to: 'checkouts#thankyou', as: 'thankyou'
  get '/get_models_by_make', to: 'vehicles#get_models_by_make'
  get '/get_years_by_model', to: 'vehicles#get_years_by_model'
end
