class Zone < ApplicationRecord
  has_many :shift_assignments, dependent: :restrict_with_exception
  has_many :user_zones, dependent: :destroy
  has_many :users, through: :user_zones

  validates :name, presence: true, uniqueness: true
  validates :position, presence: true

  scope :active_ordered, -> { where(active: true).order(:position, :id) }
end
