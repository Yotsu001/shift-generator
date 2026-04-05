class CreateEmployees < ActiveRecord::Migration[7.0]
  def change
    create_table :employees do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.integer :display_order, null: false, default: 0
      t.boolean :mixed_zone_enabled, null: false, default: false
      t.boolean :weekend_work_enabled, null: false, default: true
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end

    add_index :employees, :active
    add_index :employees, :display_order
  end
end