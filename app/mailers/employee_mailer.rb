class EmployeeMailer < ApplicationMailer
    def welcome_mail(employee, admin_email)
        @employee = employee
        mail(to: @employee.email, from: admin_email ,subject: "Welcome to Company's Leave Portal")
    end

    def leave_status_notification(employee, holiday, message, admin_email)
        @employee = employee
        @holiday = holiday
        @message = message
        mail(to: @employee.email, from: admin_email, subject: "Leave Status Notification")
    end

end
