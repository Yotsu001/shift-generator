class Employee < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :primary_zone, class_name: 'Zone', optional: true

  has_many :employee_zones, dependent: :destroy
  has_many :zones, through: :employee_zones
  has_many :shift_assignments, dependent: :restrict_with_exception
  has_many :leave_requests, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :display_order, numericality: { only_integer: true }
  validates :active, inclusion: { in: [true, false] }
  validates :mixed_zone_enabled, inclusion: { in: [true, false] }
  validates :weekend_work_enabled, inclusion: { in: [true, false] }
  validate :primary_zone_must_be_in_assignable_zones

  scope :active_ordered, -> { where(active: true).order(:display_order, :id) }

  def weekend_work_disabled
    !weekend_work_enabled
  end

  def weekend_work_disabled=(value)
    self.weekend_work_enabled = !ActiveModel::Type::Boolean.new.cast(value)
  end

  private

  def primary_zone_must_be_in_assignable_zones
    return if primary_zone_id.blank?
    return if zones.loaded? ? zones.any? { |zone| zone.id == primary_zone_id } : zones.exists?(primary_zone_id)

    errors.add(:primary_zone_id, 'は担当可能区の中から選択してください')
  end
end
