# app/controllers/api/v1/employees_controller.rb
module Api
  module V1
    class EmployeesController < ApplicationController
            # before_action :authenticate_user!
        skip_before_action :doorkeeper_authorize!, only: [:create_token, :create, :generate_code, :verify_code, :reset_password]
        before_action :current_user_admin, except: [:create_token, :create, :generate_code, :verify_code, :reset_password]
        # before_action :authenticate_admin, only: [:create, :index, :show, :update, :destroy]

        def index
          @employees = Employee.where(approval_status: "pending")
          render json: {data: @employees, message: "Employees are fetched successfully"}, status: :ok 
        end

        def show 
          @employee = Employee.find_by_id(params[:id])
          render json: {data: @employee, message: "Employee is fetched successfully"}, status: :ok
        end

        def create 
          @employee = Employee.new(emp_params)
          @employee.user_id = User.first.id
          client_app = Doorkeeper::Application.find_by(uid: params[:client_id])
          if @employee.save
               # create access token for the user, so the user won't need to login again after registration
              access_token = generate_access_token(@employee, client_app)
              render_employee_with_token(@employee, access_token)
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
          unless (@employee.approval_status == "pending" || @employee.approval_status == "False")
            if @employee && password == @employee.password
              access_token = generate_access_token(@employee, client_app)
              render json:{
                employee_id: @employee.id,
                approval_status: @employee.approval_status,
                access_token: access_token.token,
                token_type: 'bearer',
                expires_in: access_token.expires_in,
                message: "Access token generated successfully"
              }, status: :ok
            else
              render json: {error: "invalid password or email"}, status: :unprocessable_entity
              return
            end
          else
            render json: {employee: @employee, error: "Your registration request is not approved or rejected"}, status: :unauthorized
            return
          end
          
        end

        def employees_in_department
          department = params[:department]
          if Employee.departments.keys.include?(department)
            employees = Employee.where(department: department)
            render json: {employees: employees, message: "Employees in #{department} department are fetched"}, status: :ok
          else
            render json: {error: "#{department} department is not present"}
          end
        end


        # def approve_employee
        #   @employee = current_user.employees.find_by(id: params[:employee_id])
        #   admin_email = current_user.email
        #   byebug
        #   if (@employee.approval_status == "pending")
        #     if(params[:approval_status] == "True")
        #       @employee.update(approval_status: "True")
        #       message = "Your registration request has been approved by the admin."
        #       EmployeeMailer.welcome_mail(@employee, admin_email).deliver_now
        #     else (params[:approval_status] == "False")
        #       @employee.update(approval_status: "False")
        #       message = "Your registration request has been rejected by the admin."
        #       EmployeeMailer.welcome_mail(@employee, admin_email).deliver_now
        #     end
        #   else
        #     render json: {error: "Invalid paramter for approval"}, status: :unprocessable_entity
        #     return
        #   end
        #   render json: {data: @employee, message: message}, status: :ok
        # end

        def approve_employee
          @employee = Employee.find_by(id: params[:id])
          admin_email = current_user.email
          if @employee.nil?
            render json: {error: "Employee not found" ,status: :not_found}
            return
          end
          if @employee.approved? || @employee.rejected?
            render json: {error: "Employee is already approved or rejected" ,status: :unprocessable_entity}
            return
          end
          if @employee.update(approval_status: :approved)
            message = "Your registration request has been approved by the admin."
            EmployeeMailer.welcome_mail(@employee, admin_email).deliver_now
            render json: {message: "Employee is approved successfully" ,status: :ok}
          else
            render json: {message: @employee.errors.full_messages, status: :unprocessable_entity}
          end
        end

        def reject_employee
          
          @employee = Employee.find_by(id: params[:id])
          admin_email = current_user.email
          if @employee.nil?
            render json: {error: "Employee not found",status: :not_found}
            return
          end
          if @employee.approved? || @employee.rejected?
            render json: {error: "Employee has already been approved or rejected" ,status: :unprocessable_entity}
            return
          end
          if @employee.update(approval_status: :rejected)
            message = "Your registration request has been rejected by the admin."
            EmployeeMailer.rejection_mail(@employee, admin_email).deliver_now
            @employee.destroy
            render json: {message: "Employee has been rejected", status: :ok}
          else
            render json: {message: @employee.errors.full_messages ,status: :unprocessable_entity}
          end
        end

        def generate_code
          email = params[:email]
          employee = Employee.find_by(email: email)
          if employee
            code =  SecureRandom.random_number(1000..9999).to_s
            employee.update(reset_code: code, code_generated_time: Time.now)
            EmployeeMailer.send_reset_password_code(employee, code).deliver_now
            render json: {employee_id: employee.id,message: "Reset password code is sent successfully"}, status: :ok
          else
            render json: {error: "Employee with this email not found."}, status: :not_found
          end
        end

        def verify_code
          code = params[:code]
          employee_id = params[:employee_id]
          @employee = Employee.find_by(id: employee_id)
          if @employee.reset_code == code && @employee.code_generated_time >= 5.minutes.ago
            @employee.update(reset_code: nil, code_generated_time: nil)
            render json: {message: "Code is verified successfully"}, status: :ok
          else
            render json: {error: "Invalid code"}, status: :not_found
          end 
        end

        def reset_password
          employee_id = params[:employee_id]
          new_password = params[:new_password]
          confirm_password =params[:confirm_password]

          @employee = Employee.find_by(id: employee_id)
          if @employee && new_password == confirm_password
            @employee.update(password: new_password, password_confirmation: confirm_password)
            render json: {message: "Password reset successfully"}, status: :ok
          else
            render json: {error: "Invalid employee or password do not match"}, status: :unprocessable_entity
          end
        end

        private

          def emp_params
            params.require(:employee).permit(:name, :email, :department, :date_of_joining, :birth_date, :education, :passing_year, :designation ,:password, :password_confirmation)
          end

          def generate_access_token(employee, client_app)
            # application = Doorkeeper::Application.find_by(uid: params[:client_id])
            Doorkeeper::AccessToken.create(
              resource_owner_id: employee.id,
              application_id: client_app.id,
              refresh_token: SecureRandom.hex(32),
              expires_in: Doorkeeper.configuration.access_token_expires_in.to_i,
              scopes: ''
            )
            
          end

          def render_employee_with_token(employee, access_token)
            render json: {
              employee: employee,
              access_token: access_token.token,
              token_type: 'bearer',
              expires_in: access_token.expires_in,
              refresh_token: access_token.refresh_token,
              created_at: access_token.created_at.to_time.to_i
            }
          end

          def current_user_admin
            unless current_user&.admin?
              render json: {error: "You are not authorized to perform this action"}, status: :unprocessable_entity
            end
          end
          def generate_refresh_token
            loop do
              # generate a random token string and return it, 
              # unless there is already another token with the same string
              token = SecureRandom.hex(32)
              break token unless Doorkeeper::AccessToken.exists?(refresh_token: token)
            end
          end 
          def client_app
            Doorkeeper::Application.find_by(uid: params[:client_id])
          end
      end
  end
end
  