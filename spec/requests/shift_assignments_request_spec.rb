require "rails_helper"

RSpec.describe "ShiftAssignments", type: :request do
  describe "割当管理" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "未確定のシフト期間なら割当を登録できること" do
      shift_period = create(:shift_period, user: user, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 1))
      zone = create(:zone)
      employee = create(:employee, :with_zone, user: user, assignable_zone: zone)
      shift_day = shift_period.shift_days.first

      expect do
        post shift_day_shift_assignments_path(shift_day), params: {
          shift_assignment: {
            employee_id: employee.id,
            work_type: :day_shift,
            zone_id: zone.id
          }
        }
      end.to change(ShiftAssignment, :count).by(1)

      expect(response).to redirect_to(shift_period_path(shift_period))
    end

    it "不正な割当は詳細画面を再表示すること" do
      shift_period = create(:shift_period, user: user, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 1))
      zone = create(:zone)
      employee = create(:employee, :with_zone, user: user, assignable_zone: zone)
      shift_day = shift_period.shift_days.first
      create(:leave_request, shift_day: shift_day, employee: employee)

      expect do
        post shift_day_shift_assignments_path(shift_day), params: {
          shift_assignment: {
            employee_id: employee.id,
            work_type: :day_shift,
            zone_id: zone.id
          }
        }
      end.not_to change(ShiftAssignment, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("割当を更新できませんでした。入力内容を確認してください。")
    end

    it "割当を更新できること" do
      shift_period = create(:shift_period, user: user, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 1))
      zone = create(:zone)
      employee = create(:employee, :with_zone, user: user, assignable_zone: zone)
      shift_day = shift_period.shift_days.first
      assignment = create(:shift_assignment, shift_day: shift_day, employee: employee, zone: zone, work_type: :day_shift)

      patch shift_day_shift_assignment_path(shift_day, assignment), params: {
        shift_assignment: {
          employee_id: employee.id,
          work_type: :saturday_off,
          zone_id: zone.id
        }
      }

      expect(response).to redirect_to(shift_period_path(shift_period))
      expect(assignment.reload.work_type).to eq("saturday_off")
      expect(assignment.zone_id).to be_nil
    end

    it "割当を削除できること" do
      shift_period = create(:shift_period, user: user, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 1))
      zone = create(:zone)
      employee = create(:employee, :with_zone, user: user, assignable_zone: zone)
      shift_day = shift_period.shift_days.first
      assignment = create(:shift_assignment, shift_day: shift_day, employee: employee, zone: zone)

      expect do
        delete shift_day_shift_assignment_path(shift_day, assignment)
      end.to change(ShiftAssignment, :count).by(-1)

      expect(response).to redirect_to(shift_period_path(shift_period))
    end

    it "マスト要員を外すとアラートが表示されること" do
      shift_period = create(:shift_period, user: user, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 1))
      zone = create(:zone)
      required_employee = create(:employee, :with_zone, user: user, assignable_zone: zone, must_staff: true)
      shift_day = shift_period.shift_days.first
      assignment = create(:shift_assignment, shift_day: shift_day, employee: required_employee, zone: zone)

      delete shift_day_shift_assignment_path(shift_day, assignment)

      follow_redirect!
      expect(response.body).to include("マスト要員が未割当です")
    end

    it "確定済みのシフト期間では割当を登録できないこと" do
      shift_period = create(:shift_period, user: user, status: :locked, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 1))
      zone = create(:zone)
      employee = create(:employee, :with_zone, user: user, assignable_zone: zone)
      shift_day = shift_period.shift_days.first

      expect do
        post shift_day_shift_assignments_path(shift_day), params: {
          shift_assignment: {
            employee_id: employee.id,
            work_type: :day_shift,
            zone_id: zone.id
          }
        }
      end.not_to change(ShiftAssignment, :count)

      expect(response).to redirect_to(shift_period_path(shift_period))
    end
  end
end
