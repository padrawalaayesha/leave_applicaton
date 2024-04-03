class CalendarEvent < ApplicationRecord
  belongs_to :employee

  validates :title, presence: true
  validates :description, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  before_create :assign_bright_color

  BRIGHT_COLORS = Set.new

  private

  def assign_bright_color
    available_colors = generate_bright_colors(100)

    used_colors = employee.calendar_events.pluck(:color).compact
    available_colors -= used_colors

    if available_colors.present?
      self.color = available_colors.sample
    else
      self.color = available_colors.to_a.sample
    end
  end

  def generate_bright_colors(count)
    bright_colors = Set.new
    while bright_colors.length < count
      bright_color = generate_random_bright_color
      bright_colors.add(bright_color) unless BRIGHT_COLORS.include?(bright_color)
    end

    bright_colors.to_a
  end

  def generate_random_bright_color
    r = rand(100..255) 
    g = rand(100..255) 
    b = rand(100..255)

    "##{r.to_s(16).rjust(2, '0')}#{g.to_s(16).rjust(2, '0')}#{b.to_s(16).rjust(2, '0')}"
  end
end
