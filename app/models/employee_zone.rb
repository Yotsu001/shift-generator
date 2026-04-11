class EmployeeZone < ApplicationRecord
  belongs_to :employee
  belongs_to :zone

  validates :employee_id, uniqueness: { scope: :zone_id }
end
