class Employee < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :primary_zone, class_name: 'Zone', optional: true

  has_many :shift_assignments, dependent: :restrict_with_exception
  has_many :leave_requests, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :display_order, numericality: { only_integer: true }
  validates :active, inclusion: { in: [true, false] }
  validates :mixed_zone_enabled, inclusion: { in: [true, false] }
  validates :weekend_work_enabled, inclusion: { in: [true, false] }

  scope :active_ordered, -> { where(active: true).order(:display_order, :id) }
end