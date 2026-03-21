class CreateUserZones < ActiveRecord::Migration[7.1]
  def change
    create_table :user_zones do |t|
      t.references :user, null: false, foreign_key: true
      t.references :zone, null: false, foreign_key: true

      t.timestamps
    end

  add_index :user_zones, [:user_id, :zone_id], unique: true
  end
end
