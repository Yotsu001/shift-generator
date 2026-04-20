require "rails_helper"

RSpec.describe ShiftAssignment, type: :model do
  let(:shift_day) { create(:shift_day, period_start_date: Date.new(2026, 4, 15), period_end_date: Date.new(2026, 4, 17), target_date: Date.new(2026, 4, 15)) }
  let(:zone) { create(:zone) }
  let(:employee) { create(:employee, :with_zone, user: shift_day.shift_period.user, assignable_zone: zone) }

  describe "バリデーション" do
    it "平日の日勤で担当可能区があれば有効であること" do
      expect(build(:shift_assignment, shift_day: shift_day, employee: employee, zone: zone)).to be_valid
    end

    it "employee が必須であること" do
      assignment = build(:shift_assignment, shift_day: shift_day, employee: nil, zone: zone)

      expect(assignment).not_to be_valid
      expect(assignment.errors.attribute_names).to include(:employee)
    end

    it "work_type が必須であること" do
      assignment = build(:shift_assignment, shift_day: shift_day, employee: employee, zone: zone, work_type: nil)

      expect(assignment).not_to be_valid
      expect(assignment.errors.attribute_names).to include(:work_type)
    end

    it "平日日勤では zone が必須であること" do
      assignment = build(:shift_assignment, shift_day: shift_day, employee: employee, zone: nil, work_type: :day_shift)

      expect(assignment).not_to be_valid
      expect(assignment.errors[:zone]).to include("を指定してください")
    end

    it "平日夜勤では zone が必須であること" do
      assignment = build(:shift_assignment, shift_day: shift_day, employee: employee, zone: nil, work_type: :night_shift)

      expect(assignment).not_to be_valid
      expect(assignment.errors[:zone]).to include("を指定してください")
    end

    it "平日中勤では zone がなくても有効であること" do
      assignment = build(:shift_assignment, shift_day: shift_day, employee: employee, zone: nil, work_type: :middle_shift)

      expect(assignment).to be_valid
    end

    it "担当可能区でない zone は無効であること" do
      assignment = build(:shift_assignment, shift_day: shift_day, employee: employee, zone: create(:zone), work_type: :day_shift)

      expect(assignment).not_to be_valid
      expect(assignment.errors[:zone]).to include("はこの従業員の担当可能区ではありません")
    end

    it "平日は中勤を1人までしか登録できないこと" do
      create(:shift_assignment, shift_day: shift_day, employee: employee, zone: nil, work_type: :middle_shift)
      other_employee = create(:employee, user: shift_day.shift_period.user)
      assignment = build(:shift_assignment, shift_day: shift_day, employee: other_employee, zone: nil, work_type: :middle_shift)

      expect(assignment).not_to be_valid
      expect(assignment.errors[:work_type]).to include("は平日で1人までです")
    end

    it "土日祝の日勤は1人までしか登録できないこと" do
      holiday_shift_day = create(:shift_day, period_start_date: Date.new(2026, 4, 19), period_end_date: Date.new(2026, 4, 21), target_date: Date.new(2026, 4, 19), day_type: :sunday)
      holiday_zone = create(:zone)
      holiday_employee = create(:employee, :with_zone, user: holiday_shift_day.shift_period.user, assignable_zone: holiday_zone)
      create(:shift_assignment, shift_day: holiday_shift_day, employee: holiday_employee, zone: nil, work_type: :day_shift)

      other_employee = create(:employee, user: holiday_shift_day.shift_period.user)
      assignment = build(:shift_assignment, shift_day: holiday_shift_day, employee: other_employee, zone: nil, work_type: :day_shift)

      expect(assignment).not_to be_valid
      expect(assignment.errors[:work_type]).to include("は土日祝で1人までです")
    end

    it "希望休がある日に勤務を割り当てられないこと" do
      create(:leave_request, shift_day: shift_day, employee: employee)
      assignment = build(:shift_assignment, shift_day: shift_day, employee: employee, zone: zone, work_type: :day_shift)

      expect(assignment).not_to be_valid
      expect(assignment.errors[:base]).to include("希望休が登録されているため勤務を割り当てできません")
    end

    it "別ユーザー所属の従業員は割り当てできないこと" do
      assignment = build(:shift_assignment, shift_day: shift_day, employee: create(:employee), zone: zone, work_type: :day_shift)

      expect(assignment).not_to be_valid
      expect(assignment.errors[:employee]).to include("はこのシフト期間の作成者に属するスタッフを選択してください")
    end
  end

  describe "zone の制御" do
    it "休み系の勤務区分へ変更すると zone が外れること" do
      assignment = create(:shift_assignment, shift_day: shift_day, employee: employee, zone: zone, work_type: :day_shift)

      assignment.update!(work_type: :saturday_off, zone: zone)

      expect(assignment.reload.zone_id).to be_nil
      expect(assignment.work_type).to eq("saturday_off")
    end

    it "祝日の中勤では検証前に zone が外れること" do
      holiday_shift_day = create(:shift_day, period_start_date: Date.new(2026, 4, 20), period_end_date: Date.new(2026, 4, 22), target_date: Date.new(2026, 4, 20), day_type: :holiday)
      holiday_zone = create(:zone)
      holiday_employee = create(:employee, :with_zone, user: holiday_shift_day.shift_period.user, assignable_zone: holiday_zone)
      assignment = build(:shift_assignment, shift_day: holiday_shift_day, employee: holiday_employee, zone: holiday_zone, work_type: :middle_shift)

      expect(assignment).to be_valid
      expect(assignment.valid?).to be(true)
      expect(assignment.zone).to be_nil
    end
  end

  describe "employee_name" do
    it "従業員名を返すこと" do
      assignment = build(:shift_assignment, shift_day: shift_day, employee: employee, zone: zone)

      expect(assignment.employee_name).to eq(employee.name)
    end
  end
end
