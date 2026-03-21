class Zone < ApplicationRecord
  has_many :shift_assignments, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: true
  validates :position, presence: true

  scope :active_ordered, -> { where(active: true).order(:position, :id) }
end
