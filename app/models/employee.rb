class Employee < ApplicationRecord
    belongs_to :user
    has_many :holidays

    def self.authenticate(email, password)
        employee = Employee.find_by(email: email)
        employee&.valid_password?(password) ? employee : nil
    end
end
