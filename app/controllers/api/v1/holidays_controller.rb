module Api
  module V1
    class HolidaysController < ApplicationController

      def index
        if current_user.admin?
          @holidays = Holiday.where.not(h_type: "Public")
          render json: {data: @holidays, message: "Holidays request from employees are fetched successfully"}, status: :ok
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
          if emp_id == current_user.id.to_s
            @holidays = current_user.holidays
            render json: {data: @holidays , message: "List of your Holiday request"}, status: :ok
          else
            render json: {error: "You are not allowed to access the other employee's holiday request list"}, status: :not_found
          end
        end     
      end

      def create
        unless current_user.admin?
          # @employee = Employee.find_by(id: current_user.id.to_s)
          @holiday = current_user.holidays.new(holiday_params)
          @holiday.approval_status = nil
          @holiday.rejection_reason = nil
          @holiday.document_holiday.attach(params[:holiday][:document_holiday]) if params[:holiday][:document_holiday].present?
          if @holiday.valid?
            if @holiday.save
                @num_of_days = (@holiday.end_date - @holiday.start_date).to_i
                send_pending_notification_leave_mail(@employee, @holiday, @num_of_days)
                render json: {data: @holiday, message: "Holiday is created successfully"}, status: :created
            else
                render json: {error: @holiday.errors.full_messages}, status: :unprocessable_entity
            end
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
            if @holiday.approval_status.nil?
                handle_approval_admin
                # decrement_leave_count if ((@holiday.approval_status == true) && (["casual_leave", "sick_leave"].include?(@holiday.h_type)))
                increment_leave_count if ((@holiday.approval_status == true) && (["casual_leave", "sick_leave","work_from_home", "leave_without_pay"].include?(@holiday.h_type)))
            else 
              render json: {error: "Leave request has already been approved/rejected"}, status: :unprocessable_entity
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
        @public_holidays  = Holiday.where(h_type: "Public").order(:start_date)
        if @public_holidays.present?
          render json: {data: @public_holidays, message: "Public Holidays list has been fetched successfully"}, status: :ok
        else
          render json: {error: "Public Holidays list is not created"}, status: :not_found
        end
      end

      def get_pending_leaves
        if current_user.admin?
          # @pending_leaves_count = Holiday.where(approval_status: nil).where.not(employee_id: nil).group(:employee_id).count
          # @pending_leaves_count = Holiday.where(approval_status: nil).where.not(employee_id: nil).joins(:employee).group("employees.name").count
          pending_leave_details = Holiday.where(approval_status: nil).where.not(h_type: "Public").includes(:employee).map do |holiday|
            {
              employee_name: holiday.employee.name,
              holiday_details: {
                holiday_type: holiday.h_type,
                holiday_description: holiday.description,
                start_date: holiday.start_date,
                end_date: holiday.end_date,
                number_of_days: (holiday.end_date - holiday.start_date).to_i
              }
            }
          end
          
          render json: {data: pending_leave_details, message:"Number of pending leaves for each employee"}, status: :ok 
        else
          emp_id = current_user.id.to_s
          @employee = Employee.find_by(id: emp_id)
          @pending_leaves_count = @employee.holidays.where(approval_status: nil).count
          pending_leave_details = @employee.holidays.where(approval_status: nil).map do |holiday|
            employee_name = holiday.employee&.name || 'Unknown Employee'
            {
              employee_name: @employee.name,
                holiday_details: {
                  holiday_type: holiday.h_type,
                  holiday_description: holiday.description,
                  start_date: holiday.start_date,
                  end_date: holiday.end_date,
                  number_of_days: (holiday.end_date - holiday.start_date).to_i
                }
            }
          end
          render json: {data: pending_leave_details, message: "Number of pending leaves"}, status: :ok
        end
      end

 
      # def get_remaining_leaves
      #   if current_user.admin?
      #     remaining_leaves_count = {}
      #     employees = Employee.all
      #     employees.each do |employee|
      #       approved_leave_count = Holiday.where(employee_id: employee.id, approval_status: true).count
      #       remaining_leaves_count[employee.name] = [Holiday::MAX_ALLOWED_HOLIDAYS - approved_leave_count, 0].max
      #     end
      #     render json: { data: remaining_leaves_count, message: "Remaining leaves count for each employee" }, status: :ok
      #   else
      #     emp_id = current_user.id.to_s
      #     @employee = Employee.find_by(id: emp_id)
      #     @remainig_leaves_count = Holiday::MAX_ALLOWED_HOLIDAYS-@employee.holidays.where(approval_status: nil).count
      #     if @remainig_leaves_count ==0
      #       render json: {message:"You have utiized all your leave request"}, status: :ok
      #     else
      #       render json: {data: @remainig_leaves_count, message:"Number of leaves you can request"}, status: :ok
      #     end
      #   end
      # end
      def get_remaining_leaves
        if current_user.admin?
          remaining_leaves_count = {}
          employees = Employee.all
          employees.each do |employee|
            remaining_leaves_count[employee.name] = {
              casual_leave: remaining_leave_count_for_type(employee, 'casual_leave'),
              sick_leave: remaining_leave_count_for_type(employee, 'sick_leave'),
              work_from_home: remaining_leave_count_for_type(employee, 'work_from_home'),
              leave_without_pay: remaining_leave_count_for_type(employee, 'leave_without_pay')
            }
          end
          render json: { data: remaining_leaves_count, message: "Remaining leave counts for each employee and type" }, status: :ok
        else
          emp_id = current_user.id.to_s
          @employee = Employee.find_by(id: emp_id)
          remaining_leaves_count = {
            casual_leave: remaining_leave_count_for_type(@employee, 'casual_leave'),
            sick_leave: remaining_leave_count_for_type(@employee, 'sick_leave'),
            work_from_home: remaining_leave_count_for_type(@employee, 'work_from_home'),
            leave_without_pay: remaining_leave_count_for_type(@employee, 'leave_without_pay')
          }
          render json: { data: remaining_leaves_count, message: "Remaining leave counts for each type" }, status: :ok
        end
      end

      def get_approved_holidays
        if current_user.admin?
          approved_holidays = Holiday.where(approval_status: true).where.not(h_type: "Public").includes(:employee).order(:start_date)
          
          approved_holidays_details = approved_holidays.map do |holiday|
            {
              employee_name: holiday.employee&.name || 'Unknown Employee',
              holiday_details: {
                holiday_type: holiday.h_type,
                description: holiday.description,
                start_date: holiday.start_date,
                end_date: holiday.end_date,
                holiday_id: holiday.id,
                number_of_days: (holiday.end_date - holiday.start_date).to_i,
                approval_status: holiday.approval_status
              }
            }
          end
          render json: { data: approved_holidays_details, message: "List of all approved holidays" }, status: :ok
        else
          render json: { error: "You are not authorized to perform this action" }, status: :unprocessable_entity
        end
      end

      def get_approved_leave_without_pay
        if current_user.admin?
          approved_leave_without_pay = Holiday.where(h_type: "leave_without_pay", approval_status: true).includes(:employee).order(:start_date)
          approved_leave_without_pay_details = approved_leave_without_pay.map do |holiday|
            {
              employee_name: holiday.employee&.name || 'Unknown Employee',
              holiday_details: {
                holiday_type: holiday.h_type,
                description: holiday.description,
                start_date: holiday.start_date,
                end_date: holiday.end_date,
                holiday_id: holiday.id,
                number_of_days: (holiday.end_date - holiday.start_date).to_i,
                approval_status: holiday.approval_status
              }
            }
          end
          render json: {data: approved_leave_without_pay_details, message: "Leaves without pay that are approved"}, status: :ok
        else
          render json: {error: "You are not authorized to perform this action"}, status: :unprocessable_entity
        end
      end

      def get_employee_leave_details
        @employee = Employee.find_by(id: params[:employee_id])
        if @employee.present?
          if current_user.admin? || (current_user.id.to_s == params[:employee_id])
            casual_leave_details = {
              max_allowed: Holiday::MAX_CASUAL_LEAVES,
              taken: @employee.casual_leave_count.nil? ? 0 : @employee.casual_leave_count,
              remaining: remaining_leave_count_for_type(@employee, "casual_leave")
            }
            sick_leave_details = {
              max_allowed: Holiday::MAX_SICK_LEAVES,
              taken: @employee.sick_leave_count.nil? ? 0 : @employee.sick_leave_count,
              remaining: remaining_leave_count_for_type(@employee, "sick_leave")
            }
            work_from_home_details = {
              taken: @employee.work_from_home_count.nil? ? 0 : @employee.work_from_home_count
            }
            leave_without_pay_count_details = {
              taken: @employee.leave_without_pay_count.nil? ? 0 : @employee.leave_without_pay_count
            }

            render json: {
              employee_name: @employee.name,
              casual_leave_details: casual_leave_details,
              sick_leave_details: sick_leave_details,
              work_from_home_details: work_from_home_details,
              leave_without_pay_count_details: leave_without_pay_count_details
            }

          else 
            render json: {error: "You are not authorized to perform this action"}, status: :not_found
          end
        else
          render json: {error: "Employee not found "}, status: :unprocessable_entity
        end
      end

      def get_leave_details
        if current_user.admin?
          employee_leave_details = []
          employees = Employee.all
          employees.each do |employee| 
            casual_leave_details = {
              max_allowed: Holiday::MAX_CASUAL_LEAVES,
              taken: employee.casual_leave_count.nil? ? 0 : employee.casual_leave_count,
              remaining: remaining_leave_count_for_type(employee, "casual_leave")
            }
            sick_leave_details = {
              max_allowed: Holiday::MAX_SICK_LEAVES,
              taken: employee.sick_leave_count.nil? ? 0 : employee.sick_leave_count,
              remaining: remaining_leave_count_for_type(employee, "sick_leave")
            }
            work_from_home_details = {
              taken: employee.work_from_home_count.nil? ? 0 : employee.work_from_home_count
            }
            leave_without_pay_count_details = {
              taken: employee.leave_without_pay_count.nil? ? 0 : employee.leave_without_pay_count
            }
            employee_leave_details << {
              employee_name: employee.name,
              casual_leave_details: casual_leave_details,
              sick_leave_details: sick_leave_details,
              work_from_home_details: work_from_home_details,
              leave_without_pay_count_details: leave_without_pay_count_details
            }
          end
          render json: employee_leave_details, status: :ok
        else
          render json: {error: "You are not authorized to perform this action"}, status: :unprocessable_entity
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
          send_notification_leave_mail(@holiday.employee, @holiday,message)

        elsif params[:approval_status] == false
          rejection_reason = params[:rejection_reason]
          @holiday.update(approval_status: false, rejection_reason: params[:rejection_reason])
          message = "Your leave has been rejected by admin. Rejection Reason: #{rejection_reason}"
          send_notification_leave_mail(@holiday.employee, @holiday,message)

        else
          render json:{error: "Inavalid parameter for leave request"}, status: :unprocessable_entity
        end
        render json: {data: @holiday, message: message}, status: :ok
      end

      def calculate_num_of_days(start_date, end_date)
        (end_date - start_date).to_i
      end

      def send_notification_leave_mail(employee, holiday, message)
        admin_email = "padrawalaa@gmail.com"
        # num_of_days = calculate_num_of_days(holiday.start_date, holiday.end_date)
        # message = "Number of days: #{num_of_days}.\n #{message}"
        EmployeeMailer.leave_status_notification(employee, holiday, message, admin_email).deliver_now
      end

      def send_pending_notification_leave_mail(employee, holiday, num_of_days)
        employee = current_user
        admin_email = "padrawalaa@gmail.com"
        # num_of_days = calculate_num_of_days(holiday.start_date, holiday.end_date)
        message = "Your leave request is pending, the status regardng it will be provided in a week"
        EmployeeMailer.leave_status_notification(employee, holiday, message, admin_email).deliver_now
      end

      # def decrement_leave_count
      #   case @holiday.h_type
      #   when "casual_leave"
      #     @employee.decrement!(:casual_leave_count)
      #   when "sick_leave"
      #     @employee.decrement!(:sick_leave_count)
      #   end
      # end

      def remaining_leave_count_for_type(employee, h_type)
        approved_leave_count = Holiday.where(employee_id: employee.id, approval_status: true, h_type: h_type).count
      
        case h_type
        when 'casual_leave'
          max_allowed_leaves = Holiday::MAX_CASUAL_LEAVES
        when 'sick_leave'
          max_allowed_leaves = Holiday::MAX_SICK_LEAVES
        when 'work_from_home'
          max_allowed_leaves = employee.work_from_home_count
        when 'leave_without_pay'
          max_allowed_leaves = employee.leave_without_pay_count
        end
      
        if ['work_from_home', 'leave_without_pay'].include?(h_type)
          return max_allowed_leaves
        else
          return [max_allowed_leaves - approved_leave_count, 0].max
        end
      end      

      def increment_leave_count
        case @holiday.h_type
        when "work_from_home"
          @employee.increment!(:work_from_home_count)
        when "leave_without_pay"
          @employee.increment!(:leave_without_pay_count)
        when "casual_leave"
          @employee.increment!(:casual_leave_count)
        when "sick_leave"
          @employee.increment!(:sick_leave_count)
        end
      end

    end
  end
end       