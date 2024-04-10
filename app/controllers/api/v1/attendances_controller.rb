module Api
  module V1
    class AttendancesController < ApplicationController
      before_action :set_employee , only: [:checkin, :checkout]
      before_action :authorize_admin! , only: [:todays_attendances, :filter_attendances, :filter_attendances_date]

      def checkin
        @attendance = @employee.attendances.build(attendance_params)
        @attendance.checkin_image.attach(params[:attendance][:checkin_image])
        @attendance.checkin_location = JSON.parse(params[:attendance][:checkin_location])
        @attendance.checkin_time = Time.now
        @attendance.date = Time.now.to_date
        if @attendance.save
          render json: {attendance: @attendance, message: "Checked in successfull"}, status: :ok
        else
          render json: {error: @attendance.errors.full_messages}, status: :unprocessable_entity
        end
      end

      def checkout
        attendance = @employee.attendances.last
        attendance.checkout_image.attach(params[:attendance][:checkout_image])
        a_checkout_location = JSON.parse(params[:attendance][:checkout_location])   
        if attendance.present? && attendance.checkout_time.nil? && attendance.save
          attendance.update(checkout_time: Time.now, checkout_location: a_checkout_location)
          render json: {attendance: attendance, message: "Checked out successfully"}, status: :ok
        else
          render json: {error: "No check in record of the employee found"}, status: :unprocessable_entity
        end
      end

      def todays_attendances
        date = Date.today
        attendances = Attendance.includes(:employee).where(date: date)
        render json: { attendances: attendances }, include: :employee, status: :ok
      end

      def filter_attendances
        department = params[:department]
        employee_name = params[:employee_name]
        attendances = Attendance.joins(:employee)
                                 .where(employees: { department: department })
                                 .where('employees.name LIKE ?', "%#{employee_name}%")
        render json: {attendances: attendances}, status: :ok
      end

      def filter_attendances_date
        date = params[:date]
        date_final = Date.strptime(date, "%d/%m/%Y")
        attendances = Attendance.includes(:employee).where(date: date_final)
        if attendances.present?
          render json: { attendances: attendances }, include: :employee, status: :ok
        else
          render json: {error: "No attendances for this date: #{date}"}, status: :not_found
        end

      end

      private

      def set_employee
        @employee = Employee.find_by(id: params[:employee_id])
        render json: {error: "Employee not found"}, status: :not_found unless @employee.present?
      end

      def attendance_params
        params.require(:attendance).permit(:date, :checkin_time, :checkout_time, :checkin_image, :checkin_location, :checkout_location)
      end

      def authorize_admin!
        unless current_user && current_user.admin?
          render json: {message: "You are not autgorized to perform this action"}, status: :unprocessable_entity
        end
      end
    end
  end
end