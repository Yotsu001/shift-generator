class BackfillPrimaryZoneIntoEmployeeZones < ActiveRecord::Migration[7.0]
  def up
    Employee.where.not(primary_zone_id: nil).find_each do |employee|
      EmployeeZone.find_or_create_by!(employee_id: employee.id, zone_id: employee.primary_zone_id)
    end
  end

  def down
    # no-op
  end
end
