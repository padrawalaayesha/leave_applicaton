Rails.application.routes.draw do
  use_doorkeeper
  devise_for :users
  # config/routes.rb
  namespace :api do
    namespace :v1 do
      get 'get_authorization_details', to: 'homes#get_authorization_details', as: 'get_authorization_details'
      resources :employees, only: [:index, :create, :show , :update, :destroy] do
        resources :calendar_events
        collection do
          post 'create_token', to: 'employees#create_token', as: 'create_token'
          post 'generate_code' , to: 'employees#generate_code', as: 'generate_code'
          post 'verify_code/:employee_id', to: 'employees#verify_code', as: 'verify_code'
          put 'reset_password/:employee_id', to: 'employees#reset_password', as: 'reset_password'
          get 'employees_in_department', to: 'employees#employees_in_department', as: 'employees_in_department'
        end 
        member do
          put 'approve_employee', to: 'employees#approve_employee', as: 'approve_employee'
          put 'reject_employee', to: 'employees#reject_employee', as: 'reject_employee'
        end
      end
      post "users/sign_in", to: "users#sign_in"
      resources :holidays do
        collection do
          get 'index_for_employee/:employee_id', to: 'holidays#index_for_employee', as: 'index_for_employee'
          post 'upload_public_holiday', to: 'holidays#upload_public_holiday', as: 'upload_public_holiday'
          get 'get_public_holidays', to: 'holidays#get_public_holidays', as: 'get_public_holiday'
          get 'get_pending_leaves', to: 'holidays#get_pending_leaves', as: 'get_pending_leaves'
          get 'get_remaining_leaves', to: 'holidays#get_remaining_leaves', as: 'get_remaining_leaves'
          get 'get_employee_leave_details/:employee_id', to: 'holidays#get_employee_leave_details', as: 'get_employee_leave_details' 
          get 'get_leave_details_summary', to: 'holidays#get_leave_details_summary', as: 'get_leave_details_summary'
          get 'get_approved_holidays', to: 'holidays#get_approved_holidays', as: 'get_approved_holidays'
          get 'get_approved_leave_without_pay', to: 'holidays#get_approved_leave_without_pay', as: 'get_approved_leave_without_pay'
          get 'get_leave_history_for_employee', to: 'holidays#get_leave_history_for_employee', as: 'get_leave_history_for_employee'
          get 'get_leave_details_filtered', to: 'holidays#get_leave_details_filtered', as: 'get_leave_details_filtered'
          get 'get_leaves_filtered_count', to: 'holidays#get_leaves_filtered_count', as: 'get_leaves_filtered_count'
          put 'approve_holiday/:employee_id/:holiday_id', to: 'holidays#approve_holiday', as: 'approve_holiday'
          put 'approve_holiday_as_lwp/:employee_id/:holiday_id', to: 'holidays#approve_holiday_as_lwp', as: 'approve_holiday_as_lwp'
          put 'reject_holiday/:employee_id/:holiday_id', to: 'holidays#reject_holiday', as: 'reject_holiday'
          get 'get_employee_leave_record_approved', to: 'holidays#get_employee_leave_record_approved', as: 'get_employee_leave_record_approved'
          get 'get_employee_leave_record_rejected', to: 'holidays#get_employee_leave_record_rejected', as: 'get_employee_leave_record_rejected'
          get 'get_employee_approval_status', to: 'holidays#get_employee_approval_status', as: 'get_employee_approval_status'
          get 'get_employee_sick_leave_approved', to: 'holidays#get_employee_sick_leave_approved', as: 'get_employee_sick_leave_approved'
          get 'employee_leave_history_pending', to: 'holidays#employee_leave_history_pending', as: 'employee_leave_history_pending'
          get 'employee_leave_history_approved', to: 'holidays#employee_leave_history_approved', as: 'employee_leave_history_approved'
          delete 'public_holidays_destroy', to: 'holidays#public_holidays_destroy', as: 'public_holidays_destroy'
          post 'send_public_holiday', to: 'holidays#send_public_holiday', as: 'send_public_holiday'
        end
      end
    end
  end
  use_doorkeeper do
    skip_controllers :authorizations, :applications, :authorized_applications
  end
  

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
