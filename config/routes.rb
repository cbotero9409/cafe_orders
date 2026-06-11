Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions" }

  namespace :api do
    namespace :v1 do
      resources :orders, only: [ :create, :index, :show ]

      resources :products

      namespace :auth do
        post :signup
        post :login
        delete :logout
        get :me
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :products, only: [ :index ]

  resources :orders, only: [ :index, :create, :show ]

  resource :cart, only: [ :show ]
  post   "cart/add/:product_id",    to: "carts#add",    as: :add_to_cart
  delete "cart/remove/:product_id", to: "carts#remove", as: :remove_from_cart
  patch  "cart/update/:product_id", to: "carts#update", as: :update_cart_item

  root "products#index"
end
