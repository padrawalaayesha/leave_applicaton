# app/controllers/api/v1/employees_controller.rb
module Api
  module V1
    class EmployeesController < ApplicationController
            # before_action :authenticate_user!
        skip_before_action :doorkeeper_authorize!, only: :create_token
        
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
          @employee.user = current_user
          @employee.password = SecureRandom.alphanumeric(10)
          admin_email = current_user.email
          if @employee.save
              EmployeeMailer.welcome_mail(@employee, @employee.password, admin_email).deliver_now
              render json: {data: @employee, message: "Employee created succesfully"}, status: :created
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
          byebug
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


        private

          def emp_params
            params.require(:employee).permit(:name, :email, :password)
          end

          def generate_access_token(employee)
            application = Doorkeeper::Application.find_by(uid: params[:client_id])
            Doorkeeper::AccessToken.create(
              resource_owner_id: employee.user.id,
              application_id: application.id,
              refresh_token: SecureRandom.hex(32),
              expires_in: Doorkeeper.configuration.access_token_expires_in.to_i,
              scopes: ''
            )
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
  