require "rails_helper"

RSpec.describe "Employees", type: :request do
  describe "認証" do
    it "未ログイン時はスタッフ一覧からログイン画面へ遷移すること" do
      get employees_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "スタッフ管理" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "スタッフを登録できること" do
      zone = create(:zone)

      expect do
        post employees_path, params: {
          employee: {
            name: Faker::Name.name,
            zone_ids: [zone.id],
            primary_zone_id: zone.id,
            weekend_work_disabled: "1",
            mixed_zone_preferred: "1"
          }
        }
      end.to change(Employee, :count).by(1)

      employee = Employee.order(:id).last
      expect(response).to redirect_to(employees_path)
      expect(employee.user).to eq(user)
      expect(employee.zones).to include(zone)
      expect(employee.primary_zone).to eq(zone)
      expect(employee.weekend_work_enabled).to be(false)
      expect(employee.mixed_zone_preferred).to be(true)
    end

    it "スタッフ情報を更新できること" do
      original_zone = create(:zone)
      new_zone = create(:zone)
      employee = create(:employee, :with_zone, user: user, assignable_zone: original_zone)

      patch employee_path(employee), params: {
        employee: {
          name: Faker::Name.name,
          zone_ids: [new_zone.id],
          primary_zone_id: new_zone.id,
          weekend_work_disabled: "0",
          mixed_zone_preferred: "0"
        }
      }

      expect(response).to redirect_to(employees_path)
      expect(employee.reload.zones).to contain_exactly(new_zone)
      expect(employee.primary_zone).to eq(new_zone)
      expect(employee.weekend_work_enabled).to be(true)
      expect(employee.mixed_zone_preferred).to be(false)
    end

    it "スタッフを削除できること" do
      employee = create(:employee, user: user)

      expect do
        delete employee_path(employee)
      end.to change(Employee, :count).by(-1)

      expect(response).to redirect_to(employees_path)
    end
  end
end
