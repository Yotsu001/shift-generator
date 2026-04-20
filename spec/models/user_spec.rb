require "rails_helper"

RSpec.describe User, type: :model do
  it "デフォルト属性で有効であること" do
    expect(build(:user)).to be_valid
  end

  it "name が必須であること" do
    user = build(:user, name: nil)

    expect(user).not_to be_valid
    expect(user.errors.of_kind?(:name, :blank)).to be(true)
  end

  it "email が一意であること" do
    duplicate_email = Faker::Internet.unique.email(domain: "example.com")

    create(:user, email: duplicate_email)
    user = build(:user, email: duplicate_email)

    expect(user).not_to be_valid
    expect(user.errors.of_kind?(:email, :taken)).to be(true)
  end

  it "関連する shift_periods と employees を削除すること" do
    user = create(:user)
    create(:shift_period, user: user)
    create(:employee, user: user)

    expect { user.destroy }.to change(ShiftPeriod, :count).by(-1).and change(Employee, :count).by(-1)
  end
end
