require "test_helper"

class ShiftGeneration::SimpleGeneratorTest < ActiveSupport::TestCase
  test "平日は中勤候補から1人を区なし中勤にし残りでアクティブ区を埋める" do
    user = create_user("all-zones")
    zones = Array.new(6) { |index| Zone.create!(name: "区#{index + 1}", position: index + 1, active: true) }

    zones.each_with_index do |zone, index|
      create_employee(
        user: user,
        name: "スタッフ#{index + 1}",
        display_order: index,
        assignable_zones: [zone],
        primary_zone: zone,
        mixed_zone_preferred: index.zero?
      )
    end

    shift_period = ShiftPeriod.create!(
      user: user,
      name: "2026-04-13週",
      start_date: Date.new(2026, 4, 13),
      end_date: Date.new(2026, 4, 13)
    )

    ShiftGeneration::SimpleGenerator.new(shift_period).call

    shift_day = shift_period.shift_days.find_by!(target_date: Date.new(2026, 4, 13))
    middle_assignment = shift_day.shift_assignments.find_by!(work_type: :middle_shift)
    day_assignments = shift_day.shift_assignments.where(work_type: :day_shift)

    assert_equal 6, shift_day.shift_assignments.where(work_type: %i[day_shift middle_shift]).count
    assert_nil middle_assignment.zone_id
    assert_equal user.employees.active_ordered.first.id, middle_assignment.employee_id
    assert_equal zones.drop(1).map(&:id).sort, day_assignments.map(&:zone_id).sort
  end

  test "平日は休み系と希望休を優先し中勤候補から区なし中勤を入れる" do
    user = create_user("priority")
    zone_a = Zone.create!(name: "A区", position: 1, active: true)
    zone_b = Zone.create!(name: "B区", position: 2, active: true)
    zone_c = Zone.create!(name: "C区", position: 3, active: true)

    off_employee = create_employee(user: user, name: "休みスタッフ", display_order: 0, assignable_zones: [zone_a], primary_zone: zone_a)
    leave_employee = create_employee(user: user, name: "希望休スタッフ", display_order: 1, assignable_zones: [zone_b], primary_zone: zone_b, mixed_zone_preferred: true)
    middle_employee = create_employee(user: user, name: "中勤スタッフ", display_order: 2, assignable_zones: [zone_a, zone_b], primary_zone: zone_a, mixed_zone_preferred: true)
    regular_employee_a = create_employee(user: user, name: "通常スタッフA", display_order: 3, assignable_zones: [zone_a], primary_zone: zone_a)
    regular_employee_b = create_employee(user: user, name: "通常スタッフB", display_order: 4, assignable_zones: [zone_b, zone_c], primary_zone: zone_b)

    shift_period = ShiftPeriod.create!(
      user: user,
      name: "2026-04-14週",
      start_date: Date.new(2026, 4, 14),
      end_date: Date.new(2026, 4, 14)
    )
    shift_day = shift_period.shift_days.find_by!(target_date: Date.new(2026, 4, 14))

    shift_day.shift_assignments.create!(employee: off_employee, work_type: :saturday_off)
    shift_day.leave_requests.create!(employee: leave_employee)

    ShiftGeneration::SimpleGenerator.new(shift_period).call

    off_assignment = shift_day.assignment_for(off_employee)
    leave_assignment = shift_day.assignment_for(leave_employee)
    middle_assignment = shift_day.assignment_for(middle_employee)
    regular_assignments = shift_day.shift_assignments.where(employee: [regular_employee_a, regular_employee_b], work_type: :day_shift)

    assert_equal "saturday_off", off_assignment.work_type
    assert_nil leave_assignment
    assert_equal "middle_shift", middle_assignment.work_type
    assert_nil middle_assignment.zone_id
    assert_equal 2, regular_assignments.count
    assert_equal 2, regular_assignments.map(&:zone_id).uniq.count
    assert_includes regular_assignments.map(&:zone_id), zone_a.id
    assert_includes regular_assignments.map(&:zone_id), zone_b.id
  end

  test "土日は未割当スタッフを土曜は非番、日曜は週休で埋める" do
    user = create_user("weekend-rest")
    employees = 4.times.map do |index|
      create_employee(
        user: user,
        name: "週末スタッフ#{index + 1}",
        display_order: index,
        assignable_zones: [],
        weekend_work_enabled: index < 2
      )
    end

    shift_period = ShiftPeriod.create!(
      user: user,
      name: "2026-04-18週末",
      start_date: Date.new(2026, 4, 18),
      end_date: Date.new(2026, 4, 19)
    )

    saturday = shift_period.shift_days.find_by!(target_date: Date.new(2026, 4, 18))
    sunday = shift_period.shift_days.find_by!(target_date: Date.new(2026, 4, 19))
    sunday.leave_requests.create!(employee: employees.last)

    ShiftGeneration::SimpleGenerator.new(shift_period).call

    saturday_types = saturday.shift_assignments.order(:employee_id).pluck(:employee_id, :work_type).to_h
    sunday_types = sunday.shift_assignments.order(:employee_id).pluck(:employee_id, :work_type).to_h

    assert_equal 4, saturday.shift_assignments.count
    assert_equal 3, sunday.shift_assignments.count
    assert_equal %w[day_shift middle_shift saturday_off saturday_off].sort, saturday.shift_assignments.pluck(:work_type).sort
    assert_equal %w[day_shift middle_shift sunday_off].sort, sunday.shift_assignments.pluck(:work_type).sort
    assert_equal "saturday_off", saturday_types[employees[2].id]
    assert_equal "saturday_off", saturday_types[employees[3].id]
    assert_equal "sunday_off", sunday_types[employees[2].id]
    assert_nil sunday_types[employees[3].id]
  end

  test "祝日は二人出勤で残り祝日休、出勤者の祝日休は同週内で振り替える" do
    user = create_user("holiday-rest")
    employees = 4.times.map do |index|
      create_employee(
        user: user,
        name: "祝日スタッフ#{index + 1}",
        display_order: index,
        assignable_zones: [],
        weekend_work_enabled: index < 2
      )
    end

    shift_period = ShiftPeriod.create!(
      user: user,
      name: "2026-04-13祝日週",
      start_date: Date.new(2026, 4, 13),
      end_date: Date.new(2026, 4, 17)
    )

    holiday = shift_period.shift_days.find_by!(target_date: Date.new(2026, 4, 15))
    holiday.update!(day_type: :holiday)

    ShiftGeneration::SimpleGenerator.new(shift_period).call

    holiday_types = holiday.shift_assignments.order(:employee_id).pluck(:employee_id, :work_type).to_h
    weekday_rest_days = shift_period.shift_days.where(target_date: Date.new(2026, 4, 13)..Date.new(2026, 4, 17)).where.not(id: holiday.id)
    compensatory_assignments = ShiftAssignment.where(shift_day: weekday_rest_days, employee: employees.first(2), work_type: :national_holiday)

    assert_equal %w[day_shift middle_shift national_holiday national_holiday].sort, holiday.shift_assignments.pluck(:work_type).sort
    assert_equal "national_holiday", holiday_types[employees[2].id]
    assert_equal "national_holiday", holiday_types[employees[3].id]
    assert_equal 2, compensatory_assignments.count
    assert_equal employees.first(2).map(&:id).sort, compensatory_assignments.pluck(:employee_id).sort
    assert compensatory_assignments.all? { |assignment| assignment.shift_day.target_date.cweek == holiday.target_date.cweek }
  end

  private

  def create_user(suffix)
    User.create!(
      email: "#{suffix}-#{SecureRandom.hex(4)}@example.com",
      password: "password",
      name: "テストユーザー#{suffix}"
    )
  end

  def create_employee(user:, name:, display_order:, assignable_zones:, primary_zone: nil, mixed_zone_preferred: false, weekend_work_enabled: true)
    employee = user.employees.create!(
      name: name,
      display_order: display_order,
      mixed_zone_enabled: false,
      mixed_zone_preferred: mixed_zone_preferred,
      weekend_work_enabled: weekend_work_enabled
    )
    employee.zones << assignable_zones
    employee.update!(primary_zone: primary_zone) if primary_zone.present?
    employee
  end
end
