require "rails_helper"

RSpec.describe ShiftPeriod, type: :model do
  describe "バリデーション" do
    it "デフォルト属性で有効であること" do
      expect(build(:shift_period)).to be_valid
    end

    it "name が必須であること" do
      shift_period = build(:shift_period, name: nil)

      expect(shift_period).not_to be_valid
      expect(shift_period.errors.of_kind?(:name, :blank)).to be(true)
    end

    it "start_date と end_date が必須であること" do
      shift_period = build(:shift_period, start_date: nil, end_date: nil)

      expect(shift_period).not_to be_valid
      expect(shift_period.errors.of_kind?(:start_date, :blank)).to be(true)
      expect(shift_period.errors.of_kind?(:end_date, :blank)).to be(true)
    end

    it "end_date が start_date より前だと無効であること" do
      shift_period = build(:shift_period, start_date: Date.new(2026, 4, 15), end_date: Date.new(2026, 4, 14))

      expect(shift_period).not_to be_valid
      expect(shift_period.errors[:end_date]).to include("は開始日以降の日付を選択してください")
    end

    it "同じ user と開始日終了日の組み合わせは一意であること" do
      user = create(:user)
      create(:shift_period, user: user, start_date: Date.new(2026, 4, 1), end_date: Date.new(2026, 4, 30))
      duplicate = build(:shift_period, user: user, start_date: Date.new(2026, 4, 1), end_date: Date.new(2026, 4, 30))

      expect(duplicate).not_to be_valid
      expect(duplicate.errors.of_kind?(:start_date, :taken)).to be(true)
    end
  end

  describe "コールバックとクラスメソッド" do
    it "作成後に期間内の shift_days が生成されること" do
      shift_period = create(:shift_period, start_date: Date.new(2026, 4, 13), end_date: Date.new(2026, 4, 15))

      expect(shift_period.shift_days.where(target_date: shift_period.start_date..shift_period.end_date).pluck(:target_date)).to eq(
        [Date.new(2026, 4, 13), Date.new(2026, 4, 14), Date.new(2026, 4, 15)]
      )
    end

    it "曜日と祝日に応じて日種別を判定できること" do
      allow(described_class).to receive(:national_holiday?).with(Date.new(2026, 4, 16)).and_return(true)
      allow(described_class).to receive(:national_holiday?).with(Date.new(2026, 4, 15)).and_return(false)

      expect(described_class.detect_day_type_for(Date.new(2026, 4, 18))).to eq(:saturday)
      expect(described_class.detect_day_type_for(Date.new(2026, 4, 19))).to eq(:sunday)
      expect(described_class.detect_day_type_for(Date.new(2026, 4, 16))).to eq(:holiday)
      expect(described_class.detect_day_type_for(Date.new(2026, 4, 15))).to eq(:weekday)
    end

    it "HolidayJp が使える場合は national_holiday? が委譲されること" do
      stub_const("HolidayJp", class_double("HolidayJp"))
      allow(HolidayJp).to receive(:holiday?).with(Date.new(2026, 1, 1)).and_return(true)

      expect(described_class.national_holiday?(Date.new(2026, 1, 1))).to be(true)
    end
  end

  describe "rebuild_shift_days!" do
    it "期間内の shift_days を作り直すこと" do
      shift_period = create(:shift_period, start_date: Date.new(2026, 4, 13), end_date: Date.new(2026, 4, 15))
      shift_period.shift_days.find_by(target_date: Date.new(2026, 4, 14)).destroy!

      expect { shift_period.rebuild_shift_days! }.to change { shift_period.shift_days.where(target_date: shift_period.start_date..shift_period.end_date).count }.from(2).to(3)
    end
  end

  describe "refresh_day_types!" do
    it "不一致の day_type だけ更新し件数を返すこと" do
      shift_period = create(:shift_period, start_date: Date.new(2026, 4, 13), end_date: Date.new(2026, 4, 14))
      shift_day = shift_period.shift_days.first
      shift_day.update!(day_type: :holiday)

      expect(shift_period.refresh_day_types!).to eq(1)
      expect(shift_day.reload.day_type).to eq("weekday")
    end

    it "更新対象がなければ 0 を返すこと" do
      shift_period = create(:shift_period, start_date: Date.new(2026, 4, 13), end_date: Date.new(2026, 4, 14))

      expect(shift_period.refresh_day_types!).to eq(0)
    end
  end
end
