module Api
  module V1
    class CalendarEventsController < ApplicationController
      before_action :set_employee
      def index
        @calendar_events =  @employee.calendar_events
        render json: {calendar_events: @calendar_events, message: "Rendered successfully"}, status: :ok
      end

      def create
        @calendar_event = @employee.calendar_events.new(calendar_event_params)
        if @calendar_event.save
          render json: {calendar_event: @calendar_event, message: "#{@calendar_event.title} created successfully"}, status: :ok
        else
          render json: {error: @calendar_event.errors.full_messages}, status: :unprocessable_entity
        end
      end

      private

      def calendar_event_params
        params.require(:calendar_event).permit(:title, :description, :start_date, :end_date)
      end

      def set_employee
        @employee = Employee.find_by(id: params[:id])
      end
    end
  end
end