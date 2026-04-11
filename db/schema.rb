# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_04_11_094000) do
  create_table "employee_zones", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "zone_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "zone_id"], name: "index_employee_zones_on_employee_id_and_zone_id", unique: true
    t.index ["employee_id"], name: "index_employee_zones_on_employee_id"
    t.index ["zone_id"], name: "index_employee_zones_on_zone_id"
  end

  create_table "employees", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true, null: false
    t.integer "display_order", default: 0, null: false
    t.boolean "mixed_zone_enabled", default: false, null: false
    t.boolean "weekend_work_enabled", default: true, null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "mixed_zone_preferred", default: false, null: false
    t.bigint "primary_zone_id"
    t.index ["active"], name: "index_employees_on_active"
    t.index ["display_order"], name: "index_employees_on_display_order"
    t.index ["primary_zone_id"], name: "index_employees_on_primary_zone_id"
    t.index ["user_id"], name: "index_employees_on_user_id"
  end

  create_table "leave_requests", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "shift_day_id", null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "employee_id"
    t.index ["employee_id"], name: "index_leave_requests_on_employee_id"
    t.index ["shift_day_id"], name: "index_leave_requests_on_shift_day_id"
    t.index ["user_id", "shift_day_id"], name: "index_leave_requests_on_user_id_and_shift_day_id", unique: true
    t.index ["user_id"], name: "index_leave_requests_on_user_id"
  end

  create_table "shift_assignments", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "shift_day_id", null: false
    t.bigint "user_id"
    t.integer "work_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "zone_id"
    t.bigint "employee_id"
    t.index ["employee_id"], name: "index_shift_assignments_on_employee_id"
    t.index ["shift_day_id", "user_id"], name: "index_shift_assignments_on_shift_day_id_and_user_id", unique: true
    t.index ["shift_day_id"], name: "index_shift_assignments_on_shift_day_id"
    t.index ["user_id"], name: "index_shift_assignments_on_user_id"
    t.index ["zone_id"], name: "index_shift_assignments_on_zone_id"
  end

  create_table "shift_days", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "shift_period_id", null: false
    t.date "target_date", null: false
    t.integer "day_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shift_period_id", "target_date"], name: "index_shift_days_on_shift_period_id_and_target_date", unique: true
    t.index ["shift_period_id"], name: "index_shift_days_on_shift_period_id"
  end

  create_table "shift_periods", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["start_date", "end_date"], name: "index_shift_periods_on_start_date_and_end_date", unique: true
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "", null: false
    t.boolean "admin", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "zones", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_zones_on_name", unique: true
    t.index ["position"], name: "index_zones_on_position"
  end

  add_foreign_key "employee_zones", "employees"
  add_foreign_key "employee_zones", "zones"
  add_foreign_key "employees", "users"
  add_foreign_key "employees", "zones", column: "primary_zone_id"
  add_foreign_key "leave_requests", "employees"
  add_foreign_key "leave_requests", "shift_days"
  add_foreign_key "leave_requests", "users"
  add_foreign_key "shift_assignments", "employees"
  add_foreign_key "shift_assignments", "shift_days"
  add_foreign_key "shift_assignments", "users"
  add_foreign_key "shift_assignments", "zones"
  add_foreign_key "shift_days", "shift_periods"
end
