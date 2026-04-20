require "rails_helper"

RSpec.describe Zone, type: :model do
  describe "バリデーション" do
    it "デフォルト属性で有効であること" do
      expect(build(:zone)).to be_valid
    end

    it "name が必須であること" do
      zone = build(:zone, name: nil)

      expect(zone).not_to be_valid
      expect(zone.errors.of_kind?(:name, :blank)).to be(true)
    end

    it "name が一意であること" do
      duplicate_name = "#{Faker::Address.community} #{SecureRandom.hex(2)}"

      create(:zone, name: duplicate_name)
      zone = build(:zone, name: duplicate_name)

      expect(zone).not_to be_valid
      expect(zone.errors.of_kind?(:name, :taken)).to be(true)
    end

    it "position が必須であること" do
      zone = build(:zone, position: nil)

      expect(zone).not_to be_valid
      expect(zone.errors.of_kind?(:position, :blank)).to be(true)
    end
  end

  describe "スコープ" do
    it "active_ordered は有効な区を position と id 順で返すこと" do
      second = create(:zone, position: 200, active: true)
      first = create(:zone, position: 100, active: true)
      create(:zone, position: 50, active: false)

      ids = described_class.active_ordered.where(id: [first.id, second.id]).pluck(:id)
      expect(ids).to eq([first.id, second.id])
    end

    it "regular_ordered は混合区を除外すること" do
      included = create(:zone, name: "#{Faker::Address.community} #{SecureRandom.hex(2)}", position: 101, active: true)
      mixed = Zone.find_or_create_by!(name: "混合") { |zone| zone.position = 0; zone.active = true }

      ids = described_class.regular_ordered.where(id: [included.id, mixed.id]).pluck(:id)
      expect(ids).to eq([included.id])
    end
  end

  describe "関連の依存削除" do
    it "shift_assignments があると削除できないこと" do
      assignment = create(:shift_assignment)

      expect { assignment.zone.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end
  end
end
