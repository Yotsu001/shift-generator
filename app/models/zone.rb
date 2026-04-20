class Zone < ApplicationRecord
  has_many :shift_assignments, dependent: :restrict_with_exception
  has_many :employee_zones, dependent: :destroy
  has_many :employees, through: :employee_zones

  validates :name, presence: true, uniqueness: true
  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }
  validate :position_in_allowed_range

  scope :active_ordered, -> { where(active: true).order(:position, :id) }
  scope :regular_ordered, -> { active_ordered.where.not(name: '混合') }

  def self.available_positions_for(zone)
    max_position = zone.persisted? ? count : count + 1
    (1..[max_position, 1].max).to_a
  end

  def self.next_position
    count + 1
  end

  def save_with_position_adjustment
    transaction do
      save!
      rebalance_positions!
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def update_with_position_adjustment(attributes)
    assign_attributes(attributes)
    save_with_position_adjustment
  end

  private

  def position_in_allowed_range
    return if position.blank?

    allowed_positions = self.class.available_positions_for(self)
    return if allowed_positions.include?(position)

    errors.add(:position, :inclusion, value: position)
  end

  def rebalance_positions!
    ordered_ids = self.class.where.not(id: id).order(:position, :id).pluck(:id)
    ordered_ids.insert(position - 1, id)

    ordered_ids.each_with_index do |zone_id, index|
      self.class.where(id: zone_id).update_all(position: index + 1, updated_at: Time.current)
    end

    reload
  end
end
