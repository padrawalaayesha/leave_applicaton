# app/controllers/api/v1/employees_controller.rb
module Api
    module V1
      class EmployeesController < ApplicationController
            # before_action :authenticate_user!
            before_action :doorkeeper_authorize!
            before_action :authenticate_admin, only: [:create, :index, :show, :update, :destroy]

            def index
                @employees = Employee.all
                render json: {data: @employees, message: "Employees are fetched successfully"}, status: :ok 
            end
            def show 
                @employee = Employee.find(params[:id])
                render json: {data: @employee, message: "Employee is fetched successfully"}, status: :ok
            end
            def create 
                @employee = Employee.new(emp_params)
                if @employee.save
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

            private

            def emp_params
                params.require(:employee).permit(:name, :email)
            end
            def authenticate_admin
                # Use Doorkeeper's current_resource_owner
                user = current_resource_owner
        
                # Modify the condition to check if the user is an admin
                if user&.admin?
                  # No need to sign in again, as Doorkeeper will handle it
                else
                  render json: { error: "Unauthorized access" }, status: :unauthorized
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
  