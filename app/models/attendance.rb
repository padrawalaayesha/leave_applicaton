class Attendance < ApplicationRecord
  belongs_to :employee
  include Rails.application.routes.url_helpers

  has_one_attached :checkin_image
  has_one_attached :checkout_image

  validates :date , presence: true
  validate :check_in_once_a_day, on: :create
  after_update :calculate_work_hours

  def check_in_once_a_day
    if Attendance.where(employee_id: employee_id, date: date, checkout_time: nil).present?
      errors.add(:base, "Employee has already been checked in for this date")
    end
  end

  def calculate_work_hours
    if checkin_time.present? && checkout_time.present?
      work_hours = (checkout_time - checkin_time)/ 1.hour
      update_columns(hours_worked: work_hours)
    end
  end

  def as_json(options = {})
    super(options).merge(
      checkin_image: checkin_image.attached? ? url_for(checkin_image) : nil,
      checkout_image: checkout_image.attached? ? url_for(checkout_image) : nil
    )
  end
  
end
