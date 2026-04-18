require "rails_helper"

RSpec.describe "LeaveRequests", type: :request do
  describe "希望休管理" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "未確定のシフト期間なら希望休を登録できること" do
      shift_period = create(:shift_period, user: user, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 1))
      employee = create(:employee, user: user)
      shift_day = shift_period.shift_days.first

      expect do
        post shift_day_leave_requests_path(shift_day), params: {
          leave_request: {
            employee_id: employee.id,
            note: Faker::Lorem.sentence(word_count: 4)
          }
        }
      end.to change(LeaveRequest, :count).by(1)

      expect(response).to redirect_to(shift_period_path(shift_period))
    end

    it "不正な希望休は詳細画面を再表示すること" do
      shift_period = create(:shift_period, user: user, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 1))
      zone = create(:zone)
      employee = create(:employee, :with_zone, user: user, assignable_zone: zone)
      shift_day = shift_period.shift_days.first
      create(:shift_assignment, shift_day: shift_day, employee: employee, zone: zone)

      expect do
        post shift_day_leave_requests_path(shift_day), params: {
          leave_request: {
            employee_id: employee.id,
            note: Faker::Lorem.sentence(word_count: 4)
          }
        }
      end.not_to change(LeaveRequest, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("シフト期間詳細")
    end

    it "希望休を更新できること" do
      shift_period = create(:shift_period, user: user, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 1))
      employee = create(:employee, user: user)
      shift_day = shift_period.shift_days.first
      leave_request = create(:leave_request, shift_day: shift_day, employee: employee, note: Faker::Lorem.sentence(word_count: 2))
      new_note = Faker::Lorem.sentence(word_count: 6)

      patch shift_day_leave_request_path(shift_day, leave_request), params: {
        leave_request: {
          employee_id: employee.id,
          note: new_note
        }
      }

      expect(response).to redirect_to(shift_period_path(shift_period))
      expect(leave_request.reload.note).to eq(new_note)
    end

    it "希望休を削除できること" do
      shift_period = create(:shift_period, user: user, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 1))
      employee = create(:employee, user: user)
      shift_day = shift_period.shift_days.first
      leave_request = create(:leave_request, shift_day: shift_day, employee: employee)

      expect do
        delete shift_day_leave_request_path(shift_day, leave_request)
      end.to change(LeaveRequest, :count).by(-1)

      expect(response).to redirect_to(shift_period_path(shift_period))
    end

    it "確定済みのシフト期間では希望休を登録できないこと" do
      shift_period = create(:shift_period, user: user, status: :locked, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 1))
      employee = create(:employee, user: user)
      shift_day = shift_period.shift_days.first

      expect do
        post shift_day_leave_requests_path(shift_day), params: {
          leave_request: {
            employee_id: employee.id,
            note: Faker::Lorem.sentence(word_count: 4)
          }
        }
      end.not_to change(LeaveRequest, :count)

      expect(response).to redirect_to(shift_period_path(shift_period))
    end
  end
end
