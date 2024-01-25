class Holiday < ApplicationRecord
    belongs_to :employee, optional: true
    attribute :approval_status, :boolean, default: nil

    MAX_CASUAL_LEAVES = 10
    MAX_SICK_LEAVES = 5

    has_one_attached :document_holiday

    HOLIDAY_TYPES = ["casual_leave", "sick_leave", "work_from_home", "leave_without_pay"]

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
    
    
    def approved?
        approval_status == true
    end
end