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

    it "position は 1 以上であること" do
      zone = build(:zone, position: 0)

      expect(zone).not_to be_valid
      expect(zone.errors.of_kind?(:position, :greater_than)).to be(true)
    end

    it "新規作成時の position は登録数 + 1 までであること" do
      create_list(:zone, 2, position: Zone.count.next)
      zone = build(:zone, position: Zone.count + 2)

      expect(zone).not_to be_valid
      expect(zone.errors.of_kind?(:position, :inclusion)).to be(true)
    end
  end

  describe "スコープ" do
    it "active_ordered は有効な区を position と id 順で返すこと" do
      base_position = Zone.count
      first = create(:zone, position: base_position + 1, active: true)
      second = create(:zone, position: base_position + 2, active: true)
      create(:zone, position: base_position + 3, active: false)

      ids = described_class.active_ordered.where(id: [first.id, second.id]).pluck(:id)
      expect(ids).to eq([first.id, second.id])
    end

    it "regular_ordered は混合区を除外すること" do
      base_position = Zone.count
      included = create(:zone, name: "#{Faker::Address.community} #{SecureRandom.hex(2)}", position: base_position + 1, active: true)
      mixed = Zone.find_by(name: "混合") || create(:zone, name: "混合", position: Zone.count + 1, active: true)

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

  describe "表示順の自動調整" do
    it "新しい区を途中に追加すると後続の position が後ろへずれること" do
      base_position = Zone.count
      first = create(:zone, position: base_position + 1)
      second = create(:zone, position: base_position + 2)

      zone = build(:zone, position: base_position + 2)

      expect(zone.save_with_position_adjustment).to be(true)

      expect(first.reload.position).to eq(base_position + 1)
      expect(zone.reload.position).to eq(base_position + 2)
      expect(second.reload.position).to eq(base_position + 3)
    end

    it "既存の区の position を前へ移動すると他の区が連番で再調整されること" do
      base_position = Zone.count
      first = create(:zone, position: base_position + 1)
      second = create(:zone, position: base_position + 2)
      third = create(:zone, position: base_position + 3)

      expect(third.update_with_position_adjustment(position: base_position + 1)).to be(true)

      expect(third.reload.position).to eq(base_position + 1)
      expect(first.reload.position).to eq(base_position + 2)
      expect(second.reload.position).to eq(base_position + 3)
    end
  end
end
