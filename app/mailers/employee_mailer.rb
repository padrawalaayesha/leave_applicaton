class EmployeeMailer < ApplicationMailer
    def welcome_mail(employee, password, admin_email)
        @employee = employee
        @password = password
        mail(to: @employee.email, from: admin_email ,subject: "Welcome to Company's Leave Portal")
    end


end
