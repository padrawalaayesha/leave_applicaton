class Attendance < ApplicationRecord
  belongs_to :employee

  has_one_attached :checkin_image
  has_one_attached :checkout_image

  validates :date , presence: true
  validates :checkin_image, presence: true, on: :create
  validates :checkout_image, presence: true, on: :update

end
