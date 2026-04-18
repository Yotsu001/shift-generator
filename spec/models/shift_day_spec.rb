require "rails_helper"

RSpec.describe ShiftDay, type: :model do
  describe "バリデーション" do
    it "target_date が必須であること" do
      shift_period = create(:shift_period)
      shift_day = ShiftDay.new(shift_period: shift_period, target_date: nil, day_type: :weekday)

      expect(shift_day).not_to be_valid
      expect(shift_day.errors.of_kind?(:target_date, :blank)).to be(true)
    end

    it "同じ shift_period 内で target_date が一意であること" do
      shift_period = create(:shift_period)
      duplicate = ShiftDay.new(shift_period: shift_period, target_date: shift_period.start_date, day_type: :weekday)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors.of_kind?(:target_date, :taken)).to be(true)
    end
  end

  describe "従業員関連メソッド" do
    let(:shift_day) { create(:shift_day) }
    let(:employee) { create(:employee, :with_zone, user: shift_day.shift_period.user) }

    it "leave_requested_by? は希望休の有無を返すこと" do
      expect(shift_day.leave_requested_by?(employee)).to be(false)

      create(:leave_request, shift_day: shift_day, employee: employee)

      expect(shift_day.leave_requested_by?(employee)).to be(true)
      expect(shift_day.leave_requested_by?(nil)).to be(false)
    end

    it "assigned_to? は勤務割り当ての有無を返すこと" do
      expect(shift_day.assigned_to?(employee)).to be(false)

      create(:shift_assignment, shift_day: shift_day, employee: employee, zone: employee.zones.first)

      expect(shift_day.assigned_to?(employee)).to be(true)
      expect(shift_day.assigned_to?(nil)).to be(false)
    end

    it "assignment_for と leave_request_for は対象レコードを返すこと" do
      assignment = create(:shift_assignment, shift_day: shift_day, employee: employee, zone: employee.zones.first)
      other_shift_day = create(:shift_day, period_start_date: shift_day.target_date + 1.day, period_end_date: shift_day.target_date + 3.days, target_date: shift_day.target_date + 1.day)
      other_employee = create(:employee, user: other_shift_day.shift_period.user)
      leave_request = create(:leave_request, shift_day: other_shift_day, employee: other_employee)

      expect(shift_day.assignment_for(employee)).to eq(assignment)
      expect(shift_day.assignment_for(nil)).to be_nil
      expect(other_shift_day.leave_request_for(other_employee)).to eq(leave_request)
      expect(other_shift_day.leave_request_for(nil)).to be_nil
    end

    it "assignable_for? は希望休や勤務割り当てがなければ true を返すこと" do
      expect(shift_day.assignable_for?(employee)).to be(true)

      create(:leave_request, shift_day: shift_day, employee: employee)
      expect(shift_day.assignable_for?(employee)).to be(false)
      expect(shift_day.assignable_for?(nil)).to be(false)
    end
  end
end
