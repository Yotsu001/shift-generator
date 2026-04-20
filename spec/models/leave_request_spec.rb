require "rails_helper"

RSpec.describe LeaveRequest, type: :model do
  describe "バリデーション" do
    it "従業員とシフト期間の作成者が一致すれば有効であること" do
      shift_day = create(:shift_day)
      employee = create(:employee, user: shift_day.shift_period.user)

      expect(build(:leave_request, shift_day: shift_day, employee: employee)).to be_valid
    end

    it "employee が必須であること" do
      leave_request = build(:leave_request, employee: nil)

      expect(leave_request).not_to be_valid
      expect(leave_request.errors.attribute_names).to include(:employee)
    end

    it "同じ日に勤務登録がある従業員の希望休は無効であること" do
      assignment = create(:shift_assignment)
      leave_request = build(:leave_request, shift_day: assignment.shift_day, employee: assignment.employee)

      expect(leave_request).not_to be_valid
      expect(leave_request.errors[:base]).to include("すでに勤務が登録されているため希望休を登録できません")
    end

    it "別ユーザー所属の従業員は希望休を登録できないこと" do
      shift_day = create(:shift_day)
      employee = create(:employee)
      leave_request = build(:leave_request, shift_day: shift_day, employee: employee)

      expect(leave_request).not_to be_valid
      expect(leave_request.errors[:employee]).to include("はこのシフト期間の作成者に属するスタッフを選択してください")
    end
  end
end
