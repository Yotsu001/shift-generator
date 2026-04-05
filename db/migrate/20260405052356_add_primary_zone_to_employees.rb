class AddPrimaryZoneToEmployees < ActiveRecord::Migration[7.0]
  def change
    add_reference :employees, :primary_zone, foreign_key: { to_table: :zones }, null: true
  end
end