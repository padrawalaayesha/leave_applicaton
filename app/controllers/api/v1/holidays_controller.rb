module Api
    module V1

        class HolidaysController < ApplicationController
            skip_before_action :doorkeeper_authorize!

            def index
                @holiday = Holiday.all
                render json: {data: @holiday, message: "Holidays are fetched successfully"}, status: :ok
            end

            def show
                @holiday = Holiday.find_by_id(params[:id])
                render json: {data: @holiday, message: "Holiday is fetched successfully"}, status: :ok
            end
            
            def index_for_employee
                @employee = current_user.employees.find(params[:employee_id])
                @holiday = @employee.holidays
                if @holiday
                  render json: {data: @holiday , nessage: "Holidays for specific employee"}, status: :ok
                else
                    render json: {error: @holiday.errors.full_messages}, status: :unprocessable_entity
                end
            end

            def create
                @employee = current_user.employees.find(holiday_params[:employee_id])
                @holiday = @employee.holidays.create(holiday_params)
                if @holiday.save
                    render json: {data: @holiday, message: "Holiday is created successfully"}, status: :created
                else
                    render json: {error: @holiday.errors.full_messages}, status: :unprocessable_entity
                end
            end

            private

            def holiday_params
                params.require(:holiday).permit(:h_type, :description, :start_date, :end_date, :employee_id)
            end

        end
    end

end