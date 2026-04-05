class AddMixedZonePreferredToEmployees < ActiveRecord::Migration[7.0]
  def change
    add_column :employees, :mixed_zone_preferred, :boolean, null: false, default: false
  end
end