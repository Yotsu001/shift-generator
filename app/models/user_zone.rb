class UserZone < ApplicationRecord
  belongs_to :user
  belongs_to :zone

  validates :user_id, uniqueness: { scope: :zone_id }
end
