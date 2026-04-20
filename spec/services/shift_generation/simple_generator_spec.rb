require "rails_helper"

RSpec.describe ShiftGeneration::SimpleGenerator do
  describe "#call" do
    it "可能なら平日にマスト要員を最低1人割り当てること" do
      shift_period = create(:shift_period, start_date: Date.new(2026, 4, 13), end_date: Date.new(2026, 4, 13))
      zone = create(:zone)
      must_employee = create(:employee, :with_zone, user: shift_period.user, assignable_zone: zone, must_staff: true)
      create(:employee, :with_zone, user: shift_period.user, assignable_zone: zone)

      described_class.new(shift_period).call

      assignments = shift_period.shift_days.first.shift_assignments.includes(:employee)
      expect(assignments.any? { |assignment| assignment.employee_id == must_employee.id && assignment.work_type.in?(%w[day_shift middle_shift night_shift]) }).to be(true)
    end

    it "希望休を優先しマスト要員を割り当てられない日は未割当のままにすること" do
      shift_period = create(:shift_period, start_date: Date.new(2026, 4, 13), end_date: Date.new(2026, 4, 13))
      zone = create(:zone)
      must_employee = create(:employee, :with_zone, user: shift_period.user, assignable_zone: zone, must_staff: true)
      create(:leave_request, shift_day: shift_period.shift_days.first, employee: must_employee)

      described_class.new(shift_period).call

      expect(shift_period.shift_days.first.missing_must_staff?).to be(true)
      expect(shift_period.shift_days.first.shift_assignments.where(employee: must_employee)).to be_empty
    end
  end
end
