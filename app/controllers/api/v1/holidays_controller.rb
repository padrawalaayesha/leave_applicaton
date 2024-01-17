module Api
  module V1
    class HolidaysController < ApplicationController

      def index

        @holidays = Holiday.all
        render json: {data: @holidays, message: "Holidays are fetched successfully"}, status: :ok
      end

      def show
        @holiday = Holiday.find_by_id(params[:id])
        if @holiday.present?
          attached_document = @holiday.document_holiday_attachement
          render json: {data: @holiday,  attached_document: attached_document.present? ? attached_document.blob.filename : nil}, status: :ok
        else
          render json: { error: "Holiday not found" }, status: :not_found
        end
      end
          
      def index_for_employee
        @employee = current_user.employees.find(params[:employee_id])
        @holidays = @employee.holidays
        if @holidays.present?
          render json: {data: @holidays , message: "Your leave request has been accepted by the admin"}, status: :ok
        else
            render json: {error: @holidays.errors.full_messages}, status: :unprocessable_entity
        end      
      end

      def create
        @employee = current_user.employees.find_by(id: holiday_params[:employee_id])
        @holiday = @employee.holidays.new(holiday_params)
        @holiday.approval_status = nil
        @holiday.rejection_reason = nil
        @holiday.document_holiday.attach(params[:holiday][:document_holiday]) if params[:holiday][:document_holiday].present?
        if @holiday.save
            render json: {data: @holiday, message: "Holiday is created successfully"}, status: :created
        else
            render json: {error: @holiday.errors.full_messages}, status: :unprocessable_entity
        end
      end

      def approve_holiday
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
      end

      def upload_public_holiday
        @public_holiday = Holiday.create(holiday_params)
        @public_holiday.approval_status = nil
        @public_holiday.rejection_reason = nil
        if @public_holiday.save
          render json: {data: @public_holiday, message: "Admin has successfully added the public holiday"}, status: :ok
        else
          render json: {error: @public_holiday.errors.full_messages}, status: :unprocessable_entity
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

        elsif params[:approval_status] == false
          @holiday.update(approval_status: false, rejection_reason: params[:rejection_reason])
          message = "Your leave has been rejected by admin"

        elsif params[:approval_status].nil?
          @holiday.update(approval_status: nil, rejection_reason: nil)
          message = "Your leave is pending"
        else
          render json:{error: "Inavalid parameter for leave request"}, status: :unprocessable_entity
        end
        render json: {data: @holiday, message: message}, status: :ok
      end

    end
  end
end       