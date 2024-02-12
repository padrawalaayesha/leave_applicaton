class Holiday < ApplicationRecord
    belongs_to :employee, optional: true
    
    MAX_CASUAL_LEAVES = 10
    MAX_SICK_LEAVES = 6

    has_one_attached :document_holiday

    enum approval_status: { pending: 0, approved: 1, rejected: 2, approved_as_lwp: 3}
    HOLIDAY_TYPES = ["casual_leave", "sick_leave", "work_from_home", "leave_without_pay", "Public"]

    validates :h_type, presence: true, inclusion: {in: HOLIDAY_TYPES}
    validates :description , presence: true
    validates :start_date, presence: true
    validates :end_date, presence: true
    validate :validate_max_leave_count, on: :create

    def validate_max_leave_count
        case h_type
        when "casual_leave"
            validate_max_leave_count_for_type(MAX_CASUAL_LEAVES)
        when "sick_leave"
            validate_max_leave_count_for_type(MAX_SICK_LEAVES)
        end
    end

    def validate_max_leave_count_for_type(max_leave_count)
        existing_leaves_count = employee.holidays.where(h_type: h_type, approval_status: true).count
        errors.add(:base, "Maximum #{h_type.humanize} exceeded") if existing_leaves_count >= max_leave_count
    end
    
    
    # def approved?
    #     approval_status == true
    # end
end