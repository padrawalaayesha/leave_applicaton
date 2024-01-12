module Api
    module V1
        class LeavesController < ApplicationController
            def index
                @leaves = Leave.all
                render json: {data: @leaves, message: "Leaves are fetched successfully"}, status: :ok
            end

            def show
                @leave = Leave.find(params[:id])
                render json: {data: @employee, message: "Leave is fetched successfully"}, status: :ok
            end

            def create
                @employee = current_user.employees.find(params[:id])
                @leave = @employee.leaves.new(leave_params)
                if @leave.save
                    render json: {data: @leave, message: "Leave created successfully"}, status: :created
                else
                    render json: {error: @leave.errors.full_messages}, status: :unprocessable_entity
                end
            end 

            private
            def leave_params
                params.require(:leave).permit(:type, :description, :start_date, :end_date)
            end

        end
    end
end
