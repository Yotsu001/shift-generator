class Zone < ApplicationRecord
  has_many :shift_assignments, dependent: :restrict_with_exception
  has_many :employee_zones, dependent: :destroy
  has_many :employees, through: :employee_zones

  validates :name, presence: true, uniqueness: true
  validates :position, presence: true

  scope :active_ordered, -> { where(active: true).order(:position, :id) }
  scope :regular_ordered, -> { active_ordered.where.not(name: '混合') }
end
