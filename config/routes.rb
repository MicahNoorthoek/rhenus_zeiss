Rails.application.routes.draw do
  get "test/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'welcome/index', to: 'welcome#index'
  root 'sessions#new'

  resources :users do
    collection { put :all_user_lock }
    member do
      patch :toggle_lock_status
      patch :toggle_auto_email
      patch :toggle_undo_shipment_lock
      patch :toggle_client_admin
    end
  end
  resources :discrepancies

  #resources :user_logs, :except => [:show]

  resources :verified_users
  resources :selected_emails

  get 'refresh_page', to: 'dashboards#refresh_page'

  get 'active'  => 'sessions#active'
  get 'timeout' => 'sessions#timeout'

  #mount Sidekiq::Web => '/sidekiq'

    get 'dashboards/:id/edit', to: 'dashboards#edit', as: 'dashboards_edit'

  namespace :agent do
    get 'login', to: 'sessions#new'
    post 'login', to: 'sessions#create'
    #delete 'logout', to: 'sessions#destroy'
    get 'logout', to: 'sessions#destroy'

    root "dashboard#index"
  end

  #login Sessions
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  get 'session_timeout', to: 'sessions#jstimeout'
  #delete 'logout', to: 'sessions#destroy'
  get 'logout', to: 'sessions#destroy'

  get 'createuser_38923489d8234k234', to: 'users#new'
  post 'users', to: 'users#create'
  get 'users/index', to: 'users#index'
  get 'users/show', to: 'users#show'
  delete 'users', to: 'users#destroy'

  get 'users/:id/edit', to: 'users#edit' , as: 'edit_users'
  post 'users/:id/edit', to: 'users#edit', as: 'update_users'
  get 'users/:id/show', to: 'users#show', as: 'show_users'

  #dashboard
  get 'dashboard', to: 'dashboards#index'

  get 'admin', to: 'admin#index'
  #get :supports, to: "admin#index"
  get 'authorize_user', to: 'admin#authorize_user'

  get 'passwords', to: 'passwords#create'
  get 'reset_password', to: 'passwords#edit', as: 'reset_password'
  put 'update_password', to: 'passwords#update_password', as: 'update_password'
  resources :passwords, only: [:create]


  get 'admin_override', to: 'admin#admin_override'
  get 'log_user_out', to: 'admin#log_user_out'
  get 'checkifloggedout', to: 'admin#checkifloggedout'


  get 'verify_user', to: 'admin#verify_user'
  get 'forgot_password', to: 'admin#forgot_password'

  get 'lock_users', to: 'admin#lock_users'
  get 'finalize_lock_users', to: 'admin#finalize_lock_users'
  get 'parts_details', to: 'dashboards#parts_details'


end
