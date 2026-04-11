class CreateEmployeeZones < ActiveRecord::Migration[7.0]
  def change
    create_table :employee_zones do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :zone, null: false, foreign_key: true

      t.timestamps
    end

    add_index :employee_zones, [:employee_id, :zone_id], unique: true
  end
end
