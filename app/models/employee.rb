class Employee < ApplicationRecord
    # devise :database_authenticatable, :registerable,
    # :recoverable, :rememberable, :validatable
    belongs_to :user
    has_many :holidays, dependent: :destroy
    has_many :calendar_events, dependent: :destroy

    attribute :casual_leave_count, default: 0
    attribute :sick_leave_count, default: 0
    attribute :work_from_home_count, default: 0
    attribute :leave_without_pay_count, default: 0

    enum department: {IT: 1, Sales: 2, HR: 3, Account: 4, Testing: 5, Admin: 6}
    enum approval_status: {pending: 0, approved: 1, rejected: 2}
    validates :name , presence: true, length: {minimum: 3, maximum: 25}
    VALID_EMAIL_REGX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    validates :email, presence: true, uniqueness: {case_sensitive: false}, format: {with: VALID_EMAIL_REGX} ,length: {maximum: 105}
    validates :department, presence: true
    validates :date_of_joining, presence: true
    validates :department , presence: true
    validates :designation, presence: true
    validates :birth_date, presence: true
    validates :education, presence: true
    validates :passing_year, presence: true
    validates :password, presence: true, confirmation: true, length: {minimum: 6, maximum: 12}, on: :create
    validates :password_confirmation, presence: true, on: :create



    def self.authenticate(email, password)
        employee = Employee.find_by(email: email)
        employee&.valid_password?(password) ? employee : nil
    end
end
   