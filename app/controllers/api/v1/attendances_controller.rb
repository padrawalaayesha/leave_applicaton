module Api
  module V1
    class AttendancesController < ApplicationController
      before_action :set_employee

      def checkin
        @attendance = @employee.attendances.build(attendance_params)
        binding.pry
        @attendance.checkin_image.attach(params[:attendance][:checkin_image])
        @attendance.location = JSON.parse(params[:attendance][:location])
        if @attendance.save
          render json: {attendance: @attendance, message: "Checked in successfull"}, status: :ok
        else
          render json: {error: @attendance.errors.full_messages}, status: :unprocessable_entity
        end
      end

      def checkout
        attendance = @employee.attendances.last
        attendance.checkout_image.attach(params[:checkout_image])
        if attendance.present? && attendance.checkout_time.nil? && attendance.save
          attendance.update(checkout_time: Time.now)
          render json: {attendance: attendance, message: "Checked out successfully"}, status: :ok
        else
          render json: {error: "No check in record of the employee found"}, status: :unprocessable_entity
        end
      end

      private

      def set_employee
        @employee = Employee.find_by(id: params[:employee_id])
        render json: {error: "Employee not found"}, status: :not_found unless @employee.present?
      end

      def attendance_params
        params.require(:attendance).permit(:date, :checkin_time, :checkout_time, :checkin_image, :location)
      end
    end
  end
end