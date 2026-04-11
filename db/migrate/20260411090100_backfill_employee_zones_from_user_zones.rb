class BackfillEmployeeZonesFromUserZones < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      INSERT INTO employee_zones (employee_id, zone_id, created_at, updated_at)
      SELECT employees.id, user_zones.zone_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM employees
      INNER JOIN user_zones ON user_zones.user_id = employees.user_id
      WHERE employees.user_id IS NOT NULL
    SQL
  end

  def down
    execute <<~SQL
      DELETE employee_zones
      FROM employee_zones
      INNER JOIN employees ON employees.id = employee_zones.employee_id
      INNER JOIN user_zones ON user_zones.user_id = employees.user_id
                         AND user_zones.zone_id = employee_zones.zone_id
    SQL
  end
end
