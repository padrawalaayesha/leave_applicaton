module Api
  module V1
    class HolidaysController < ApplicationController

      before_action :current_user, only: [:index, :get_leave_details_summary, :get_employee_leave_record_approved]

      def index
        if @current_user.admin?
          @holidays = Holiday.where(approval_status: "pending").where.not(h_type: "Public")
          holiday_details = @holidays.map do |holiday|
            {
              employee_id: holiday.employee.id,
              holiday_id: holiday.id,
              employee_name: holiday.employee.name,
              department: holiday.employee.department,
              h_type: holiday.h_type,
              reason: holiday.description,
              start_date: holiday.start_date,
              end_date: holiday.end_date,
              number_of_days: holiday.number_of_days,
              document_attached: holiday.document_holiday.attached?,
              document_url: holiday.document_holiday.attached? ? url_for(holiday.document_holiday) : nil
            }
          end
          render json: {data: holiday_details, message: "Holidays request from employees are fetched successfully"}, status: :ok
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
              render json: {error: @holidays.errors.full_messages.join(" ")}, status: :unprocessable_entity
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
          @holiday.approval_status = :pending
          @holiday.number_of_days = count_working_days(@holiday.start_date, @holiday.end_date)
          
          date = Time.now
          # @holiday.document_holiday.attach(params[:holiday][:document_holiday]) unless params[:holiday][:document_holiday] == "null"
          if @holiday.start_date >= date && @holiday.end_date >= date
            if @holiday.save
                @holiday.document_holiday.attach(params[:document_holiday]) if params[:document_holiday].present?
                send_pending_notification_leave_mail(@employee, @holiday)
                render json: {data: @holiday, message: "Holiday is created successfully"}, status: :created
              else
                render json: {error: @holiday.errors.full_messages}, status: :unprocessable_entity
              end  
            else
                render json: {error: "The year should be same as current year"}, status: :unprocessable_entity
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
            if @holiday.approval_status == "pending"
                approve_holiday_action
            else 
              render json: {error: "Leave request has already been approved/rejected"}, status: :unprocessable_entity
            end  
          else
            render json: {error: "Holiday not found"}, status: :not_found
          end
        else
          render json: {error: "You are not authorized to perform this action"}, status: :unprocessable_entity
        end
      end


      def approve_holiday_as_lwp
        if current_user.admin?
          @employee = current_user.employees.find_by(id: params[:employee_id])
          @holiday = @employee.holidays.find_by(id: params[:holiday_id])
          if @holiday
            if @holiday.approval_status == "pending"
              approve_lwp_action
            else
              render json: {message: "You have already approved/rejected this leave request"}, status: :unprocessable_entity
            end
          else
            render json: {error: "Holiday not found"}, status: :not_found
          end
        else
          render json: {error: "You are not authorized to perform this action"}, status: :unprocessable_entity
        end
      end

      def reject_holiday
        if current_user.admin?
          @employee = current_user.employees.find_by(id: params[:employee_id])
          @holiday = @employee.holidays.find_by(id: params[:holiday_id])

          if @holiday
            if @holiday.approval_status == "pending"
                reject_holiday_action
            else 
              render json: {error: "Leave request has already been approved/rejected"}, status: :unprocessable_entity
            end  
          else
            render json: {error: "Holiday not found"}, status: :not_found
          end
        else
          render json: {error: "You are not authorized to perform this action"}, status: :unprocessable_entity
        end
      end

      def upload_public_holiday
        if current_user.admin?
          
          @public_holiday = Holiday.new(holiday_params)
          @public_holiday.approval_status = :approved 
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
          public_holidays_with_name = @public_holidays.map do |holiday|
            {
              description: holiday.description,
              holiday_id: holiday.id,
              holiday_type: holiday.h_type,
              start_date: holiday.start_date,
              end_date: holiday.end_date,
              day: holiday.start_date.strftime("%A")
            }
          end
          render json: {data: public_holidays_with_name, message: "Public Holidays list has been fetched successfully"}, status: :ok
      end

      def send_public_holiday
        year = Time.now.year.to_s
        holidays = Holiday.where("strftime('%Y', start_date) = ?", year)
        public_holidays = holidays.where(h_type: "Public").order(:start_date)
        if public_holidays.any?
          approved_employees = Employee.where(approval_status: "approved")
          if approved_employees.any?
            approved_employees.each do |employee|
              EmployeeMailer.public_holidays_email(employee, public_holidays).deliver_now
            end
            render json: {message: "Email sent to the employees successfully"}, status: :ok
          else
            render json: {message: "There are no employees present"}, status: :not_found
          end
        else
          render json: {message: "There are no public holidays availabel"}, status: :not_found
        end
      end

      def update
        if current_user.admin? 
           @public_holiday = Holiday.find(params[:id])
          
           if @public_holiday.h_type == "Public"
            @public_holiday.update(holiday_params)
            render json: {public_holiday: @public_holiday, message: "You have successfully updated the public holiday", status: :ok}
           else
            render json: {error: "You can only update the public holidays", status: :unprocessable_entity}
           end
        else
          render json: {error: "You are not authorized to perform this action", status: :unauthorized}
          end
      end
  
      def destroy
        if current_user.admin?
          @public_holiday = Holiday.find(params[:id])
          if @public_holiday.h_type == "Public"
            @public_holiday.destroy
            render json: {message: "Public holiday deleted successfully", status: :ok}
          else  
            render json: {error: "You can only delete the public holidays", status: :unprocessable_entity}
          end
        else
          render json: {error: "You are not authorized to perform this action"}, status: :unauthorized
        end
      end

      def public_holidays_destroy
        if current_user.admin?
          year = params[:year].to_s
          
          if year.present?
            holidays =  holidays = Holiday.where("strftime('%Y', start_date) = ?", year)
            public_holidays = holidays.where(h_type: "Public").order(:start_date)
            public_holidays.destroy_all
            render json: {message: "All public holidays of #{year} are deleted successfully", status: :ok}
          else
            render json: {message: "Year must be present", status: :unprocessable_entity}
          end
        else
          render json: {error: "You are not authorrized to perform this action", status: :unauthorized}
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
                number_of_days: (holiday.end_date - holiday.start_date).to_i,
                approval_status: "pending"
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

      def employee_leave_history_pending
        @holidays = current_user.holidays
        @pending_leaves = @holidays.where(approval_status: "pending")
        if
          render json: {pending: @pending_leaves}, status: :ok
        else
          render json: {message: "#{current_user.name} does not any leaves that are pending"}, status: :not_found
        end     
      end

      def employee_leave_history_approved
        @holidays = current_user.holidays
        @approved_holidays = @holidays.where(approval_status: "approved").order(start_date: :desc)
        year = params[:year].to_s

        if year.present?
          @approved_holidays_year = @approved_holidays.where("(strftime('%Y', start_date) = ? OR strftime('%Y', end_date) = ?) AND start_date <= ? AND end_date >= ? AND (start_date >= ? OR end_date <= ?)", year, year, "#{year}-12-31", "#{year}-01-01", "#{year}-01-01", "#{year}-12-31")
          render json: {approved_leaves: @approved_holidays_year}, status: :ok
          return
        else
          if @approved_holidays
            render json: {approved_leaves: @approved_holidays}, status: :ok
          else
            render json: {message: "#{current_user.name} does not have any approved leaves"}, status: :not_found
          end
        end
      end

      def get_employee_leave_details
        
        employee = Employee.find_by(id: params[:employee_id])
        year = Time.now.year.to_s
        if employee.present?
          if current_user.admin? || (current_user.id.to_s == params[:employee_id])
            
            holidays = employee.holidays.where("(strftime('%Y', start_date) = ? OR strftime('%Y', end_date) = ?) AND start_date <= ? AND end_date >= ? AND (start_date >= ? OR end_date <= ?)", year, year, "#{year}-12-31", "#{year}-01-01", "#{year}-01-01", "#{year}-12-31")
            holidays = holidays.where(approval_status: "approved")
            
            casual_leave_count = 0
            sick_leave_count = 0
            work_from_home_count = 0
            leave_without_pay_count =0
            year = year.to_i
            holidays.each do |holiday|
              leave_days_within_year = holiday.counting_days_in_year[year]
        
              case holiday.h_type
              when "casual_leave"
                casual_leave_count += leave_days_within_year.to_i if leave_days_within_year.present?
              when "sick_leave"
                sick_leave_count += leave_days_within_year.to_i if leave_days_within_year.present?
              when "work_from_home"
                work_from_home_count += leave_days_within_year.to_i if leave_days_within_year.present?
              when "leave_without_pay"
                leave_without_pay_count += leave_days_within_year.to_i if leave_days_within_year.present?
              end
            end
            leave_details = {
            employee_name: employee.name,
            casual_leave_details: {
              max_allowed: Holiday::MAX_CASUAL_LEAVES,
              taken: casual_leave_count ,
              remaining: [0, Holiday::MAX_CASUAL_LEAVES - casual_leave_count].max
            },
      
            sick_leave_details: {
              max_allowed: Holiday::MAX_SICK_LEAVES,
              taken: sick_leave_count,
              remaining: [0, Holiday::MAX_SICK_LEAVES - sick_leave_count].max
            },
      
            work_from_home_details: {
              taken: work_from_home_count
            },
      
            leave_without_pay_details: {
              taken: leave_without_pay_count
            },
          } 

          total_count_sick_casual = casual_leave_count + sick_leave_count
          allowed_sick_casual = Holiday::MAX_SICK_LEAVES + Holiday::MAX_CASUAL_LEAVES
          remaining_sick_casual = allowed_sick_casual - total_count_sick_casual

          render json: {leave_details: leave_details, total: total_count_sick_casual, allowed: allowed_sick_casual, remaining: remaining_sick_casual}, status: :ok 

          else 
            render json: {error: "You are not authorized to perform this action"}, status: :not_found
          end
        else
          render json: {error: "Employee not found "}, status: :unprocessable_entity
        end
      end

      def get_employee_approval_status
        employee = current_user
        year = Time.now.year.to_s
        if employee
          holidays = employee.holidays.where("strftime('%Y', start_date) = ?", year)
          approved_pending_holidays = holidays.where(approval_status: ["pending","approved"])
          p_holidays = Holiday.where("strftime('%Y', start_date) = ?", year)
          public_holidays = p_holidays.where(h_type: "Public")
          render json: {approved_pending_holidays: approved_pending_holidays,
            public_holidays: public_holidays
            }, status: :ok
        else
          render json: {error: "Employee not found"}, status: :not_found
        end
      end

      def get_leave_details_summary
        if @current_user.admin?
          department = params[:department]
          employee_name = params[:employee_name]
          year = params[:year]
          if year.blank?
            render json: { error: "Department, name, and year must be present" }, status: :unprocessable_entity
            return    
          end
      
          employee = Employee.find_by(id: params[:employee_id])
          if employee.nil?
            render json: { error: "Employee not found" }, status: :not_found
            return
          end  
          
          holidays = employee.holidays.where("(strftime('%Y', start_date) = ? OR strftime('%Y', end_date) = ?) AND start_date <= ? AND end_date >= ? AND (start_date >= ? OR end_date <= ?)", year, year, "#{year}-12-31", "#{year}-01-01", "#{year}-01-01", "#{year}-12-31")
          holidays = holidays.where(approval_status: "approved")
          
          casual_leave_count = 0
          sick_leave_count = 0
          work_from_home_count = 0
          leave_without_pay_count =0
          year = year.to_i
          holidays.each do |holiday|
            leave_days_within_year = holiday.counting_days_in_year[year]
      
            case holiday.h_type
            when "casual_leave"
              casual_leave_count += leave_days_within_year.to_i if leave_days_within_year.present?
            when "sick_leave"
              sick_leave_count += leave_days_within_year.to_i if leave_days_within_year.present?
            when "work_from_home"
              work_from_home_count += leave_days_within_year.to_i if leave_days_within_year.present?
            when "leave_without_pay"
              leave_without_pay_count += leave_days_within_year.to_i if leave_days_within_year.present?
            end
          end
      
          leave_details = {
            employee_name: employee.name,
            designation: employee.designation,
            department: employee.department,
            casual_leave_details: {
              max_allowed: Holiday::MAX_CASUAL_LEAVES,
              taken: casual_leave_count ,
              remaining: [0, Holiday::MAX_CASUAL_LEAVES - casual_leave_count].max
            },
      
            sick_leave_details: {
              max_allowed: Holiday::MAX_SICK_LEAVES,
              taken: sick_leave_count,
              remaining: [0, Holiday::MAX_SICK_LEAVES - sick_leave_count].max
            },
      
            work_from_home_details: {
              taken: work_from_home_count
            },
      
            leave_without_pay_details: {
              taken: leave_without_pay_count
            },
          }  
      
          render json: leave_details, status: :ok
        else
          render json: { error: "You are not authorized to perform this action" }, status: :unprocessable_entity
        end
      end
      

      def get_employee_leave_record_rejected
        if current_user.admin?
          year = params[:year]
          if year.blank?
            render json: { error: "Department, name, and year must be present" }, status: :unprocessable_entity
            return    
          end
          holidays = Holiday.rejected
          holidays = holidays.where(employee_id: params[:employee_id])
          holidays = holidays.where("(strftime('%Y', start_date) = ? OR strftime('%Y', end_date) = ?) AND start_date <= ? AND end_date >= ? AND (start_date >= ? OR end_date <= ?)", year, year, "#{year}-12-31", "#{year}-01-01", "#{year}-01-01", "#{year}-12-31")
          render json: { rejected_holidays: holidays}, status: :ok
        else
          render json: {error: "You are not authorized to perform this action"}, status: :unprocessable_entity
        end
      end

      def get_leave_details_filtered
        if current_user.admin?
          year = params[:year]
          if params[:h_type].present?
            case params[:h_type]
            when "casual_leave"
              holidays = Holiday.casual_leave
              
            when "sick_leave"
              holidays = Holiday.sick_leave
              
            when "work_from_home"
              holidays = Holiday.work_from_home
              
            when "leave_without_pay"
              holidays = Holiday.leave_without_pay
            else
              holidays = Holiday.all
            end
            holidays = holidays.where(employee_id: params[:employee_id])
            holidays = holidays.where("(strftime('%Y', start_date) = ? OR strftime('%Y', end_date) = ?) AND start_date <= ? AND end_date >= ? AND (start_date >= ? OR end_date <= ?)", year, year, "#{year}-12-31", "#{year}-01-01", "#{year}-01-01", "#{year}-12-31")
            render json: { holidays: holidays}, status: :ok
          else
            holidays = Holiday.all
            holidays = holidays.where(employee_id: params[:employee_id])
            holidays = holidays.where("(strftime('%Y', start_date) = ? OR strftime('%Y', end_date) = ?) AND start_date <= ? AND end_date >= ? AND (start_date >= ? OR end_date <= ?)", year, year, "#{year}-12-31", "#{year}-01-01", "#{year}-01-01", "#{year}-12-31")
            render json: { holidays: holidays}, status: :ok
          end
        else
          render json: {error: "You are not authorized to perform this action"}, status: :unprocessable_entity
        end
      end

      def get_leaves_filtered_count
        if current_user.admin?
          year = params[:year]
          department = params[:department]
          if year.blank? || department.blank?
            return render json: {error: "Year and department must be present"}, status: :unprocessable_entity
            return  
          end
          department_id = Employee.departments[department]
          employees = Employee.where(department: department_id)
          
          leave_counts = {
            casual_leave_count: 0,
            sick_leave_count: 0,
            work_from_home_count: 0,
            leave_without_pay_count: 0
          }
          employees.each do |employee| 
            year = year.to_s
            holidays = employee.holidays.where("(strftime('%Y', start_date) = ? OR strftime('%Y', end_date) = ?) AND start_date <= ? AND end_date >= ? AND (start_date >= ? OR end_date <= ?)", year, year, "#{year}-12-31", "#{year}-01-01", "#{year}-01-01", "#{year}-12-31")
            holidays = holidays.where(approval_status: "approved")
            year = year.to_i
            holidays.each do |holiday|
              leave_days_within_year = holiday.counting_days_in_year[year]

              case holiday.h_type
              when "sick_leave"
                leave_counts[:sick_leave_count] += leave_days_within_year.to_i if leave_days_within_year.present?
              when "casual_leave"
                leave_counts[:casual_leave_count] += leave_days_within_year.to_i if leave_days_within_year.present?
              when "work_from_home"
                leave_counts[:work_from_home_count] += leave_days_within_year.to_i if leave_days_within_year.present?
              when "leave_without_pay"
                leave_counts[:leave_without_pay_count] += leave_days_within_year.to_i if leave_days_within_year.present?
              end
            end
          end

          render json: {counts: leave_counts}, status: :ok
        else
          render json: {error: "You are not authorized to perform this action"}, status: :unprocessable_entity
        end
      end

      private

      def public_holiday_params
        params.require(:holiday).permit(:date ,:name)
      end

      def holiday_params
        params.require(:holiday).permit(:h_type, :description, :start_date, :end_date, :employee_id, :approval_status, :rejection_reason)
      end

      # def handle_approval_admin
      #   if params[:approval_status] == true
      #     @holiday.update(approval_status: true,rejection_reason: nil)
      #     message = "Your leave has been accepted by admin" 
      #     send_notification_leave_mail(@holiday.employee, @holiday,message)

      #   elsif params[:approval_status] == false
      #     rejection_reason = params[:rejection_reason]
      #     @holiday.update(approval_status: false, rejection_reason: params[:rejection_reason])
      #     message = "Your leave has been rejected by admin. Rejection Reason: #{rejection_reason}"
      #     send_notification_leave_mail(@holiday.employee, @holiday,message)

      #   else
      #     render json:{error: "Inavalid parameter for leave request"}, status: :unprocessable_entity
      #   end
      #   render json: {data: @holiday, message: message}, status: :ok
      # end

      def approve_holiday_action
        @holiday.update(approval_status: :approved, sandwich_weekend: params[:sandwich_weekend])
        number_of_days = @holiday.counting_days_in_year
        @holiday.update(number_of_days: number_of_days)
        
        message = "Your leave request has been accepted by the admin"
        send_notification_leave_mail(@holiday.employee,@holiday, message)
        render json: {data: @holiday, message: "Holiday request is approved by the admin"}, status: :ok
      end

      def approve_lwp_action
        @holiday.update(approval_status: :approved_as_lwp, h_type: "leave_without_pay" )
        number_of_days = @holiday.counting_days_in_year
        @holiday.update(number_of_days: number_of_days)
        message = "Your leave request has been accepted as leave without pay by the admin"
        send_notification_leave_mail(@holiday.employee,@holiday, message)
        render json: {data: @holiday, message: "Holiday request is approved by the admin"}, status: :ok
      end

      def reject_holiday_action
        rejection_reason = params[:rejection_reason]
        @holiday.update(approval_status: :rejected, rejection_reason: rejection_reason)
        
        message = "Your leave request has been rejected by the admin"
        send_notification_leave_mail(@holiday.employee, @holiday, message)
        render json: {data: @holiday, message: "Holiday request is rejected by the admin"}, status: :ok
      end

      def calculate_num_of_days(start_date, end_date)
        (end_date - start_date).to_i
      end

      def send_notification_leave_mail(employee, holiday, message)
        admin_email = "padrawalaa@gmail.com"
        EmployeeMailer.leave_status_notification(employee, holiday, message, admin_email).deliver_now
      end

      def send_pending_notification_leave_mail(employee, holiday)
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
      
      def count_working_days(start_date, end_date)
        current_date = start_date
        count = 0
        while current_date <= end_date
          unless current_date.saturday? || current_date.sunday?
            count += 1
          end
          current_date += 1.day
        end
        count
      end

      # def increment_leave_count
      #   case @holiday.h_type
      #   when "work_from_home"
      #     @employee.increment!(:work_from_home_count)
      #   when "leave_without_pay"
      #     @employee.increment!(:leave_without_pay_count)
      #   when "casual_leave"
      #     @employee.increment!(:casual_leave_count)
      #   when "sick_leave"
      #     @employee.increment!(:sick_leave_count)
      #   end
      # end

      def holiday_details_for_type(employee, h_type)
        employee.holidays.where(h_type: h_type).where.not(approval_status: :pending).map do |holiday|
          details = {
            description: holiday.description,
            start_date: holiday.start_date,
            end_date: holiday.end_date,
            number_of_days: (holiday.end_date - holiday.start_date).to_i,
            approval_status: holiday.approval_status,
            # rejection_reason: holiday.rejection_reason if holiday.approval_status == false
          }
          details[:rejection_reason] = holiday.rejection_reason if holiday.approval_status == false
          details
        end
      end

    end
  end
end       