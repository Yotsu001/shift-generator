class AddMustStaffToEmployees < ActiveRecord::Migration[7.1]
  def change
    add_column :employees, :must_staff, :boolean, default: false, null: false
    add_index :employees, :must_staff
  end
end
