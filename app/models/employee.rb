class Employee < ApplicationRecord
    belongs_to :user
    has_many :holidays

    validates :name , presence: true, uniqueness: {case_senistive: true}, length: {minimum: 3, maximum: 25}
    VALID_EMAIL_REGX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    validates :email, presence: true, uniqueness: {case_sensitive: false}, format: {with: VALID_EMAIL_REGX} ,length: {maximum: 105}

    def self.authenticate(email, password)
        employee = Employee.find_by(email: email)
        employee&.valid_password?(password) ? employee : nil
    end
end
