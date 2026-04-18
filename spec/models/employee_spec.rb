require "rails_helper"

RSpec.describe Employee, type: :model do
  describe "バリデーション" do
    it "デフォルト属性で有効であること" do
      expect(build(:employee)).to be_valid
    end

    it "name が必須であること" do
      employee = build(:employee, name: nil)

      expect(employee).not_to be_valid
      expect(employee.errors.of_kind?(:name, :blank)).to be(true)
    end

    it "display_order は整数のみ許可されること" do
      employee = build(:employee, display_order: 1.5)

      expect(employee).not_to be_valid
      expect(employee.errors.of_kind?(:display_order, :not_an_integer)).to be(true)
    end

    it "active は true または false が必須であること" do
      employee = build(:employee, active: nil)

      expect(employee).not_to be_valid
      expect(employee.errors.of_kind?(:active, :inclusion)).to be(true)
    end

    it "mixed_zone_enabled は true または false が必須であること" do
      employee = build(:employee, mixed_zone_enabled: nil)

      expect(employee).not_to be_valid
      expect(employee.errors.of_kind?(:mixed_zone_enabled, :inclusion)).to be(true)
    end

    it "weekend_work_enabled は true または false が必須であること" do
      employee = build(:employee, weekend_work_enabled: nil)

      expect(employee).not_to be_valid
      expect(employee.errors.of_kind?(:weekend_work_enabled, :inclusion)).to be(true)
    end

    it "primary_zone が担当可能区に含まれていれば有効であること" do
      zone = create(:zone)
      employee = create(:employee)
      employee.zones << zone
      employee.primary_zone = zone

      expect(employee).to be_valid
    end

    it "primary_zone が担当可能区に含まれていなければ無効であること" do
      employee = build(:employee, primary_zone: create(:zone))

      expect(employee).not_to be_valid
      expect(employee.errors[:primary_zone_id]).to include("は担当可能区の中から選択してください")
    end

    it "担当可能区を読み込み済みでも primary_zone の検証が動くこと" do
      employee = create(:employee)
      employee.zones.load
      employee.primary_zone = create(:zone)

      expect(employee).not_to be_valid
      expect(employee.errors[:primary_zone_id]).to include("は担当可能区の中から選択してください")
    end
  end

  describe "スコープ" do
    it "active_ordered は有効な従業員を表示順と id 順で返すこと" do
      later = create(:employee, display_order: 2, active: true)
      first = create(:employee, display_order: 1, active: true)
      create(:employee, display_order: 0, active: false)

      ids = described_class.active_ordered.where(id: [first.id, later.id]).pluck(:id)
      expect(ids).to eq([first.id, later.id])
    end
  end

  describe "weekend_work_disabled" do
    it "weekend_work_enabled の反転値を返すこと" do
      expect(build(:employee, weekend_work_enabled: true).weekend_work_disabled).to be(false)
      expect(build(:employee, weekend_work_enabled: false).weekend_work_disabled).to be(true)
    end
  end

  describe "weekend_work_disabled= " do
    it "入力値を真偽値として解釈して weekend_work_enabled を反転すること" do
      employee = build(:employee, weekend_work_enabled: true)

      employee.weekend_work_disabled = "1"
      expect(employee.weekend_work_enabled).to be(false)

      employee.weekend_work_disabled = "0"
      expect(employee.weekend_work_enabled).to be(true)
    end
  end

  describe "関連の依存削除" do
    it "shift_assignments があると削除できないこと" do
      assignment = create(:shift_assignment)

      expect { assignment.employee.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    it "leave_requests があると削除できないこと" do
      leave_request = create(:leave_request)

      expect { leave_request.employee.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end
  end
end
