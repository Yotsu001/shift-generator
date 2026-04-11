class RemoveMixedZoneFromEmployeeZones < ActiveRecord::Migration[7.0]
  def up
    mixed_zone = Zone.find_by(name: '混合')
    return if mixed_zone.blank?

    EmployeeZone.where(zone_id: mixed_zone.id).delete_all
  end

  def down
    # no-op
  end
end
