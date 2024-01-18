Rails.application.routes.draw do
  use_doorkeeper
  devise_for :users
  # config/routes.rb
  namespace :api do
    namespace :v1 do
      resources :employees, only: [:index, :create, :show , :update, :destroy] do
        collection do
          post 'create_token', to: 'employees#create_token', as: 'create_token'
        end
      end
      post "users/sign_in", to: "users#sign_in"
      resources :holidays, only: [ :index, :show, :create] do
        collection do
          get 'index_for_employee/:employee_id', to: 'holidays#index_for_employee', as: 'index_for_employee'
          patch 'approve/:employee_id/:holiday_id', to: 'holidays#approve_holiday', as: 'approve_holiday'
          post 'upload_public_holiday', to: 'holidays#upload_public_holiday', as: 'upload_public_holiday'
          get 'get_public_holidays', to: 'holidays#get_public_holidays', as: 'get_public_holiday'
          get 'get_pending_leaves', to: 'holidays#get_pending_leaves', as: 'get_pending_leaves'
          get 'get_remaining_leaves', to: 'holidays#get_remaining_leaves', as: 'get_remaining_leaves'
        end
      end
    end
  end
  use_doorkeeper do
    skip_controllers :authorizations, :applications, :authorized_applications
  end
  

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
