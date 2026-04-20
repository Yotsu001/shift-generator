require "rails_helper"

RSpec.describe "ShiftPeriods", type: :request do
  describe "認証" do
    it "未ログイン時はシフト期間一覧からログイン画面へ遷移すること" do
      get shift_periods_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "シフト期間管理" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "シフト期間を作成すると詳細画面へ遷移し shift_days も作られること" do
      start_date = Date.new(2026, 5, 1)
      end_date = Date.new(2026, 5, 3)

      expect do
        post shift_periods_path, params: {
          shift_period: {
            name: Faker::Lorem.words(number: 2).join(" "),
            start_date: start_date,
            end_date: end_date
          }
        }
      end.to change(ShiftPeriod, :count).by(1)

      shift_period = ShiftPeriod.order(:id).last
      expect(response).to redirect_to(shift_period_path(shift_period))
      expect(shift_period.shift_days.order(:target_date).pluck(:target_date)).to eq([start_date, start_date + 1.day, end_date])
    end

    it "日付範囲を更新すると shift_days を再作成すること" do
      shift_period = create(:shift_period, user: user, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 3))

      patch shift_period_path(shift_period), params: {
        shift_period: {
          name: shift_period.name,
          start_date: Date.new(2026, 5, 10),
          end_date: Date.new(2026, 5, 12),
          status: shift_period.status
        }
      }

      expect(response).to redirect_to(shift_periods_path)
      expect(shift_period.reload.shift_days.order(:target_date).pluck(:target_date)).to eq([
        Date.new(2026, 5, 10),
        Date.new(2026, 5, 11),
        Date.new(2026, 5, 12)
      ])
    end

    it "確定済みのシフト期間は削除できないこと" do
      shift_period = create(:shift_period, user: user, status: :locked)

      expect do
        delete shift_period_path(shift_period)
      end.not_to change(ShiftPeriod, :count)

      expect(response).to redirect_to(shift_periods_path)
    end

    it "自動生成を実行できること" do
      shift_period = create(:shift_period, user: user)
      generator = instance_double(ShiftGeneration::SimpleGenerator, call: true)

      allow(ShiftGeneration::SimpleGenerator).to receive(:new).with(shift_period).and_return(generator)

      post generate_shift_period_path(shift_period)

      expect(response).to redirect_to(shift_period_path(shift_period))
      expect(ShiftGeneration::SimpleGenerator).to have_received(:new).with(shift_period)
      expect(generator).to have_received(:call)
    end

    it "割当を全削除できること" do
      shift_period = create(:shift_period, user: user, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 2))
      zone = create(:zone)
      employee = create(:employee, :with_zone, user: user, assignable_zone: zone)
      create(:shift_assignment, shift_day: shift_period.shift_days.first, employee: employee, zone: zone)

      expect do
        delete clear_assignments_shift_period_path(shift_period)
      end.to change(ShiftAssignment, :count).by(-1)

      expect(response).to redirect_to(shift_period_path(shift_period))
    end

    it "シフト期間一覧の各行に詳細画面への遷移先が含まれること" do
      shift_period = create(:shift_period, user: user)

      get shift_periods_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(data-href="#{shift_period_path(shift_period)}"))
    end
  end
end
