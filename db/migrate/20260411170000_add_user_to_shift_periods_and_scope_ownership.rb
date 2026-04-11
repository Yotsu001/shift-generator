class AddUserToShiftPeriodsAndScopeOwnership < ActiveRecord::Migration[7.1]
  class MigrationShiftPeriod < ApplicationRecord
    self.table_name = "shift_periods"
  end

  class MigrationEmployee < ApplicationRecord
    self.table_name = "employees"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def up
    add_reference :shift_periods, :user, foreign_key: true, null: true

    backfill_shift_period_user_ids!
    ensure_employee_user_ids_present!

    change_column_null :shift_periods, :user_id, false
    change_column_null :employees, :user_id, false

    remove_index :shift_periods, column: [:start_date, :end_date]
    add_index :shift_periods, [:user_id, :start_date, :end_date], unique: true
  end

  def down
    remove_index :shift_periods, column: [:user_id, :start_date, :end_date]
    add_index :shift_periods, [:start_date, :end_date], unique: true

    change_column_null :employees, :user_id, true
    change_column_null :shift_periods, :user_id, true

    remove_reference :shift_periods, :user, foreign_key: true
  end

  private

  def backfill_shift_period_user_ids!
    unresolved_ids = []
    fallback_user_id = single_user_id

    MigrationShiftPeriod.find_each do |shift_period|
      candidate_user_ids = candidate_user_ids_for(shift_period.id)
      candidate_user_ids = [fallback_user_id] if candidate_user_ids.empty? && fallback_user_id.present?

      if candidate_user_ids.one?
        shift_period.update_columns(user_id: candidate_user_ids.first)
      else
        unresolved_ids << shift_period.id
      end
    end

    return if unresolved_ids.empty?

    raise ActiveRecord::IrreversibleMigration,
          "shift_periods.user_id を決められないレコードがあります: #{unresolved_ids.join(', ')}"
  end

  def ensure_employee_user_ids_present!
    fallback_user_id = single_user_id

    if fallback_user_id.present?
      MigrationEmployee.where(user_id: nil).update_all(user_id: fallback_user_id)
    end

    unresolved_ids = MigrationEmployee.where(user_id: nil).pluck(:id)
    return if unresolved_ids.empty?

    raise ActiveRecord::IrreversibleMigration,
          "employees.user_id が未設定のレコードがあります: #{unresolved_ids.join(', ')}"
  end

  def single_user_id
    user_ids = MigrationUser.order(:id).pluck(:id)
    user_ids.one? ? user_ids.first : nil
  end

  def candidate_user_ids_for(shift_period_id)
    sql = <<~SQL
      SELECT DISTINCT candidate_user_id
      FROM (
        SELECT sa.user_id AS candidate_user_id
        FROM shift_assignments sa
        INNER JOIN shift_days sd ON sd.id = sa.shift_day_id
        WHERE sd.shift_period_id = #{shift_period_id} AND sa.user_id IS NOT NULL

        UNION

        SELECT lr.user_id AS candidate_user_id
        FROM leave_requests lr
        INNER JOIN shift_days sd ON sd.id = lr.shift_day_id
        WHERE sd.shift_period_id = #{shift_period_id} AND lr.user_id IS NOT NULL

        UNION

        SELECT employees.user_id AS candidate_user_id
        FROM shift_assignments sa
        INNER JOIN shift_days sd ON sd.id = sa.shift_day_id
        INNER JOIN employees ON employees.id = sa.employee_id
        WHERE sd.shift_period_id = #{shift_period_id} AND employees.user_id IS NOT NULL

        UNION

        SELECT employees.user_id AS candidate_user_id
        FROM leave_requests lr
        INNER JOIN shift_days sd ON sd.id = lr.shift_day_id
        INNER JOIN employees ON employees.id = lr.employee_id
        WHERE sd.shift_period_id = #{shift_period_id} AND employees.user_id IS NOT NULL
      ) candidates
    SQL

    select_values(sql).map(&:to_i)
  end
end