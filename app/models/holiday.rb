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

    
    scope :casual_leave, -> { where(h_type: "casual_leave", approval_status: "approved") }
    scope :sick_leave, -> { where(h_type: "sick_leave", approval_status: "approved")}
    scope :work_from_home, -> { where(h_type: "work_from_home", approval_status: "approved") }
    scope :leave_without_pay, -> { where(h_type: "leave_without_pay", approval_status: "approved") }

    scope :rejected , -> { where(approval_status: "rejected")}

    def validate_max_leave_count
        case h_type
        when "casual_leave"
            validate_max_leave_count_for_type(MAX_CASUAL_LEAVES)
        when "sick_leave"
            validate_max_leave_count_for_type(MAX_SICK_LEAVES)
        end
    end

    # def validate_max_leave_count_for_type(max_leave_count)
    #     year = start_date.year
    #     holidays = employee.holidays.where("strftime('%Y', start_date) = ?", year.to_s)
    #     existing_leaves_count = holidays.where(h_type: h_type, approval_status: :approved).sum(:number_of_days)
    #     remaining_leaves = [0, max_leave_count - existing_leaves_count].max
    #     if number_of_days > remaining_leaves
    #       errors.add(:base, "Only a maximum of #{max_leave_count} days of #{h_type.humanize} is allowed. You have #{remaining_leaves} remaining days.") 
    #       return
    #     end
    # end
    
    def validate_max_leave_count_for_type(max_leave_count)
        start_year = start_date.year
        end_year = end_date.year
    
        (start_year..end_year).each do |year|
            holidays_in_year = employee.holidays.where("strftime('%Y', start_date) = ?", year.to_s)
            existing_leaves_count = holidays_in_year.where(h_type: h_type, approval_status: :approved).sum(:number_of_days)
            remaining_leaves = [0, max_leave_count - existing_leaves_count].max
            if year == start_year && number_of_days > remaining_leaves
                errors.add(:base, "Only a maximum of #{max_leave_count} days of #{h_type.humanize} is allowed for #{year}. You have #{remaining_leaves} remaining days.") 
            elsif year != start_year && number_of_days > max_leave_count
                errors.add(:base, "Only a maximum of #{max_leave_count} days of #{h_type.humanize} is allowed for #{year}. You have exceeded the maximum leave count for #{year}.")
            end
        end
    end

    def counting_days_in_year
        dates_array = (start_date..end_date).to_a
        dates_count = Hash.new(0)
        dates_array.each do |date|
            dates_count[date.year] += 1
        end
        dates_count
    end
    
      
    
    # def approved?
    #     approval_status == true
    # end
end