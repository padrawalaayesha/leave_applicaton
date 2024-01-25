class Holiday < ApplicationRecord
    belongs_to :employee, optional: true
    attribute :approval_status, :boolean, default: nil

    MAX_ALLOWED_HOLIDAYS = 15
    
    def approved?
        approval_status == true
    end
end