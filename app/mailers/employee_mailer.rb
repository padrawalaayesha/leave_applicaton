class EmployeeMailer < ApplicationMailer
    def welcome_mail(employee, admin_email)
        @employee = employee
        mail(to: @employee.email, from: admin_email ,subject: "Welcome to Company's Leave Portal")
    end

    def rejection_mail(employee, admin_email)
        @employee = employee
        @admin_email = admin_email
        mail(to: @employee.email, from: @admin_email, subject: "Registration Rejection on Leave Portal")
    end

    def leave_status_notification(employee, holiday, message, admin_email)
        @employee = employee
        @holiday = holiday
        @message = message
        mail(to: @employee.email, from: admin_email, subject: "Leave Status Notification")
    end
    
    def send_reset_password_code(employee, code)
        @employee = employee
        @code = code
        mail(to: @employee.email, from: "padrawalaa@gmail.com", subject: "Re-set Password Code")
    end

    def public_holidays_email(employee, public_holidays)
        @employee = employee
        @public_holidays = public_holidays
        mail(to: @employee.email, subject: "Public Holidays Information")
    end

end
