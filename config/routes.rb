Rails.application.routes.draw do
  use_doorkeeper
  devise_for :users
  # config/routes.rb
  namespace :api do
    namespace :v1 do
      resources :employees, only: [:index, :create, :show , :update, :destroy] do
        collection do
          post 'create_token', to: 'employees#create_token', as: 'create_token'
          post 'generate_code' , to: 'employees#generate_code', as: 'generate_code'
          post 'verify_code/:employee_id', to: 'employees#verify_code', as: 'verify_code'
          put 'reset_password/:employee_id', to: 'employees#reset_password', as: 'reset_password'
        end 
        member do
          put 'approve_employee', to: 'employees#approve_employee', as: 'approve_employee'
          put 'reject_employee', to: 'employees#reject_employee', as: 'reject_employee'
        end
      end
      post "users/sign_in", to: "users#sign_in"
      resources :holidays, only: [ :index, :show, :create] do
        collection do
          get 'index_for_employee/:employee_id', to: 'holidays#index_for_employee', as: 'index_for_employee'
          put 'approve/:employee_id/:holiday_id', to: 'holidays#approve_holiday', as: 'approve_holiday'
          post 'upload_public_holiday', to: 'holidays#upload_public_holiday', as: 'upload_public_holiday'
          get 'get_public_holidays', to: 'holidays#get_public_holidays', as: 'get_public_holiday'
          get 'get_pending_leaves', to: 'holidays#get_pending_leaves', as: 'get_pending_leaves'
          get 'get_remaining_leaves', to: 'holidays#get_remaining_leaves', as: 'get_remaining_leaves'
          get 'get_employee_leave_details/:employee_id', to: 'holidays#get_employee_leave_details', as: 'get_employee_leave_details' 
          get 'get_leave_details', to: 'holidays#get_leave_details', as: 'get_leave_details'
          get 'get_approved_holidays', to: 'holidays#get_approved_holidays', as: 'get_approved_holidays'
          get 'get_approved_leave_without_pay', to: 'holidays#get_approved_leave_without_pay', as: 'get_approved_leave_without_pay'
          get 'get_leave_history_for_employee', to: 'holidays#get_leave_history_for_employee', as: 'get_leave_history_for_employee'
          get 'get_leave_details_filtered', to: 'holidays#get_leave_details_filtered', as: 'get_leave_details_filtered'
          get 'get_leaves_filtered_count', to: 'holidays#get_leaves_filtered_count', as: 'get_leaves_filtered_count'
        end
      end
    end
  end
  use_doorkeeper do
    skip_controllers :authorizations, :applications, :authorized_applications
  end
  

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
