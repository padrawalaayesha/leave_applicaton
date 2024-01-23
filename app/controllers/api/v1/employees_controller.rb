# app/controllers/api/v1/employees_controller.rb
module Api
  module V1
    class EmployeesController < ApplicationController
            # before_action :authenticate_user!
        skip_before_action :doorkeeper_authorize!, only: [:create_token, :create]
        before_action :current_user_admin, except: [:create_token]
        # before_action :authenticate_admin, only: [:create, :index, :show, :update, :destroy]

        def index
          @employees = Employee.all
          render json: {data: @employees, message: "Employees are fetched successfully"}, status: :ok 
        end

        def show 
          @employee = Employee.find_by_id(params[:id])
          render json: {data: @employee, message: "Employee is fetched successfully"}, status: :ok
        end

        def create 
          @employee = Employee.new(emp_params)
          @employee.user_id = 1
          if @employee.save
              render json: {data: @employee, message: "Employee registration successfully. Waiting for approval"}, status: :created
          else
              render json: {error: @employee.errors.full_messages}, status: :unprocessable_entity
          end
        end 

        def update 
          @employee = Employee.find_by_id(params[:id])
          if @employee.update(emp_params)
              render json: {data: @employee, message: "Employee updated successfully"}, status: :ok
          else
              render json: {error: @employee.errors.full_messages}, status: :unprocessable_entity
          end
        end

        def destroy
          @employee = Employee.find_by_id(params[:id])
          @employee.destroy
          head :no_content
        end


        def create_token
          email = params[:email]
          password = params[:password]

          @employee = Employee.find_by(email: email)
          if @employee
            access_token = generate_access_token(@employee)
            render json:{
              access_token: access_token.token,
              token_type: 'bearer',
              expires_in: access_token.expires_in,
              message: "Access token generated successfully"
            }, status: :ok
          else
            render json: {error: "invalid password or email"}, status: :unprocessable_entity
          end
          
        end


        def approve_employee
          @employee = current_user.employees.find_by(id: params[:employee_id])
          admin_email = current_user.email
          if (@employee.approval_status == "pending")
            if(params[:approval_status] == "True")
              @employee.update(approval_status: "True")
              message = "Your registration request has been approved by the admin."
              EmployeeMailer.welcome_mail(@employee, admin_email).deliver_now
            else (params[:approval_status] == "False")
              @employee.update(approval_status: "False")
              message = "Your registration request has been rejected by the admin."
              EmployeeMailer.welcome_mail(@employee, admin_email).deliver_now
            end
          else
            render json: {error: "Invalid paramter for approval"}, status: :unprocessable_entity
          end
          render json: {data: @employee, message: message}, status: :ok
        end

        private

          def emp_params
            params.require(:employee).permit(:name, :email, :department, :date_of_joining, :birth_date, :education, :passing_year, :designation ,:password, :password_confirmation)
          end

          def generate_access_token(employee)
            application = Doorkeeper::Application.find_by(uid: params[:client_id])
            Doorkeeper::AccessToken.create(
              resource_owner_id: employee.id,
              application_id: application.id,
              refresh_token: SecureRandom.hex(32),
              expires_in: Doorkeeper.configuration.access_token_expires_in.to_i,
              scopes: ''
            )
          end
          def current_user_admin
            unless current_user&.admin?
              render json: {error: "You are not authorized to perform this action"}, status: :unprocessable_entity
            end
          end
              # def authenticate_admin
              #     user = User.find_by(email: params[:email])
              #     if user&.admin? && user.valid_password?(params[:password])
              #         sign_in(user, store: false)
              #     else
              #         render json:{error: "Unauthorized access"}, status: :unauthorized
              #     end
              # end
      end
  end
end
  