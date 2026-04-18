require "rails_helper"

RSpec.describe EmployeeZone, type: :model do
  it "従業員と区の組み合わせが一意なら有効であること" do
    expect(build(:employee_zone)).to be_valid
  end

  it "従業員と区の組み合わせが重複すると無効であること" do
    employee = create(:employee)
    zone = create(:zone)
    create(:employee_zone, employee: employee, zone: zone)

    duplicate = build(:employee_zone, employee: employee, zone: zone)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors.of_kind?(:employee_id, :taken)).to be(true)
  end
end
