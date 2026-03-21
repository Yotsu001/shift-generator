class AddNameAndAdminToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :name, :string, null: false, default: ""
    add_column :users, :admin, :boolean, null: false, default: false
  end
end
