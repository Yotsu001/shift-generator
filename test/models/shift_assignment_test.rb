require "test_helper"

class ShiftAssignmentTest < ActiveSupport::TestCase
  test "休み系へ変更すると zone は自動で外れる" do
    user = User.create!(
      email: "shift-assignment-#{SecureRandom.hex(4)}@example.com",
      password: "password",
      name: "テストユーザー"
    )
    zone = Zone.create!(name: "テスト区#{SecureRandom.hex(3)}", position: 1, active: true)
    employee = user.employees.create!(
      name: "スタッフ",
      display_order: 0,
      mixed_zone_enabled: false,
      mixed_zone_preferred: false,
      weekend_work_enabled: true,
      primary_zone: zone
    )
    employee.zones << zone

    shift_period = ShiftPeriod.create!(
      user: user,
      name: "テスト期間#{SecureRandom.hex(3)}",
      start_date: Date.new(2026, 4, 15),
      end_date: Date.new(2026, 4, 15)
    )
    shift_day = shift_period.shift_days.find_by!(target_date: Date.new(2026, 4, 15))

    assignment = shift_day.shift_assignments.create!(
      employee: employee,
      work_type: :day_shift,
      zone: zone
    )

    assignment.update!(work_type: :saturday_off, zone: zone)

    assert_nil assignment.reload.zone_id
    assert_equal "saturday_off", assignment.work_type
  end
end
