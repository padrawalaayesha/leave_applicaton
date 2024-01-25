module Api
  module V1
    class HolidaysController < ApplicationController

      def index
        if current_user.admin?
          @holidays = Holiday.all
          render json: {data: @holidays, message: "Holidays are fetched successfully"}, status: :ok
        else
          render json: {error: "You are not authorized to perform this action"}, status: :unprocessable_entity
        end

      end

      def show
        if current_user.admin?
          @holiday = Holiday.find_by_id(params[:id])
          if @holiday.present?
            attached_document = @holiday.document_holiday_attachment
            render json: {data: @holiday,  attached_document: attached_document.present? ? attached_document.blob.filename : nil}, status: :ok
          else
            render json: { error: "Holiday not found" }, status: :not_found
          end
        else
          employee_id = current_user.id
          @holiday = Holiday.find_by_id(params[:id])
          if employee_id == @holiday.employee_id
            attached_document = @holiday.document_holiday_attachment
            render json: {data: @holiday,  attached_document: attached_document.present? ? attached_document.blob.filename : nil}, status: :ok
          else
            render json: { error: "You are not allowed to access the other employee's holiday requests" }, status: :not_found
          end 
        end
      end
          
      def index_for_employee
        if current_user.admin?
          @employee = current_user.employees.find(params[:employee_id])
          @holidays = @employee.holidays
          if @holidays.present?
            render json: {data: @holidays , message: "List of Holidays for specific employee"}, status: :ok
          else
              render json: {error: @holidays.errors.full_messages}, status: :unprocessable_entity
          end 
        else
          emp_id = params[:employee_id]
          byebug
          if emp_id == current_user.id.to_s
            @holidays = Holiday.where(employee_id: emp_id)
            render json: {data: @holidays , message: "List of your Holiday request"}, status: :ok
          else
            render json: {error: "You are not allowed to access the other employee's holiday request list"}, status: :not_found
          end
        end     
      end

      def create
        unless current_user.admin?
          @employee = current_user.employees.find_by(id: holiday_params[:employee_id])
          @holiday = @employee.holidays.new(holiday_params)
          @holiday.approval_status = nil
          @holiday.rejection_reason = nil
          @holiday.document_holiday.attach(params[:holiday][:document_holiday]) if params[:holiday][:document_holiday].present?
          if @holiday.save
              send_pending_notification_leave_mail(@employee, @holiday)
              render json: {data: @holiday, message: "Holiday is created successfully"}, status: :created
          else
              render json: {error: @holiday.errors.full_messages}, status: :unprocessable_entity
          end
        else
          render json: {error: "Only employees are allowed to create leave request"}, status: :unprocessable_entity 
        end
      end

      def approve_holiday
        if current_user.admin?
          @employee = current_user.employees.find_by(id: params[:employee_id])
          @holiday = @employee.holidays.find_by(id: params[:holiday_id])

          if @holiday
              if @employee.holidays.where(approval_status: true).count < Holiday::MAX_ALLOWED_HOLIDAYS || params[:approval_status].nil?
                handle_approval_admin
              else
                render json: {error: "Employee has already reached the maximum allowed leave request that is 15"}, status: :unprocessable_entity
              end
          else
            render json: {error: @holiday.errors.full_messages}, status: :unprocessable_entity
          end
        else
          render json: {error: "You are not authorized to perform this action"}, status: :unprocessable_entity
        end
      end

      def upload_public_holiday
        if current_user.admin?
          @public_holiday = Holiday.create(holiday_params)
          @public_holiday.approval_status = nil
          @public_holiday.rejection_reason = nil
          if @public_holiday.save
            render json: {data: @public_holiday, message: "Admin has successfully added the public holiday"}, status: :ok
          else
            render json: {error: @public_holiday.errors.full_messages}, status: :unprocessable_entity
          end
        else
          render json: {error: "You are not authorized to perform this action"}, status: :unprocessable_entity
        end
      end

      def get_public_holidays
        @public_holidays  = Holiday.where(h_type: "Public")
        if @public_holidays.present?
          render json: {data: @public_holidays, message: "Public Holidays list has been fetched successfully"}, status: :ok
        else
          render json: {error: "Public Holidays list is not created"}, status: :not_found
        end
      end

      def get_pending_leaves
        if current_user.admin?
          # @pending_leaves_count = Holiday.where(approval_status: nil).where.not(employee_id: nil).group(:employee_id).count
          @pending_leaves_count = Holiday.where(approval_status: nil).where.not(employee_id: nil).joins(:employee).group("employees.id", "employees.name").count
          render json: {data: @pending_leaves_count, message:"Number of pending leaves for each employee"}, status: :ok 
        else
          emp_id = current_user.id.to_s
          @employee = Employee.find_by(id: emp_id)
          @pending_leaves_count = @employee.holidays.where(approval_status: nil).count
          render json: {data: @pending_leaves_count, message: "Number of pending leaves"}, status: :ok
        end
      end

      def get_remaining_leaves
        if current_user.admin?
          remaining_leaves_count = {}
          employees = Employee.all
          employees.each do |employee|
            approved_leave_count = Holiday.where(employee_id: employee.id, approval_status: true).count
            remaining_leaves_count[employee.name] = [Holiday::MAX_ALLOWED_HOLIDAYS - approved_leave_count, 0].max
          end
          render json: { data: remaining_leaves_count, message: "Remaining leaves count for each employee" }, status: :ok
        else
          emp_id = current_user.id.to_s
          @employee = Employee.find_by(id: emp_id)
          @remainig_leaves_count = Holiday::MAX_ALLOWED_HOLIDAYS-@employee.holidays.where(approval_status: nil).count
          if @remainig_leaves_count ==0
            render json: {message:"You have utiized all your leave request"}, status: :ok
          else
            render json: {data: @remainig_leaves_count, message:"Number of leaves you can request"}, status: :ok
          end
        end
      end

      private

      def public_holiday_params
        params.require(:holiday).permit(:date ,:name)
      end

      def holiday_params
        params.require(:holiday).permit(:h_type, :description, :start_date, :end_date, :employee_id, :approval_status, :rejection_reason, :document_holiday)
      end

      def handle_approval_admin
        if params[:approval_status] == true
          @holiday.update(approval_status: true,rejection_reason: nil)
          message = "Your leave has been accepted by admin" 
          send_notification_leave_mail(@holiday.employee, message)

        elsif params[:approval_status] == false
          rejection_reason = params[:rejection_reason]
          @holiday.update(approval_status: false, rejection_reason: params[:rejection_reason])
          message = "Your leave has been rejected by admin. Rejection Reason: #{rejection_reason}"
          send_notification_leave_mail(@holiday.employee, message)

        else
          render json:{error: "Inavalid parameter for leave request"}, status: :unprocessable_entity
        end
        render json: {data: @holiday, message: message}, status: :ok
      end

      def send_notification_leave_mail(employee, message)
        admin_email = "padrawalaa@gmail.com"
        EmployeeMailer.leave_status_notification(employee, @holiday, message, admin_email).deliver_now
      end

      def send_pending_notification_leave_mail(employee, holiday)
        admin_email = "padrawalaa@gmail.com"
        message = "Your leave request is pending, the status regardng it will be provided in a week"
        EmployeeMailer.leave_status_notification(employee, holiday, message, admin_email).deliver_now
      end
    end
  end
end       