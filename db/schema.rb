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

ActiveRecord::Schema[7.1].define(version: 2026_03_21_082110) do
  create_table "shift_assignments", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "shift_day_id", null: false
    t.bigint "user_id", null: false
    t.string "zone_name", null: false
    t.integer "work_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shift_day_id", "user_id"], name: "index_shift_assignments_on_shift_day_id_and_user_id", unique: true
    t.index ["shift_day_id"], name: "index_shift_assignments_on_shift_day_id"
    t.index ["user_id"], name: "index_shift_assignments_on_user_id"
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

  add_foreign_key "shift_assignments", "shift_days"
  add_foreign_key "shift_assignments", "users"
  add_foreign_key "shift_days", "shift_periods"
end
