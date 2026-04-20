require "rails_helper"

RSpec.describe "スタッフ管理", type: :system do
  it "スタッフを画面から登録できること" do
    user = create(:user, password: "password123")
    zone = create(:zone)
    employee_name = Faker::Name.name

    login_as_user(user)
    visit new_employee_path

    fill_in "スタッフ名", with: employee_name
    check zone.name
    select zone.name, from: "主担当区"
    check "土日祝出勤不可にする"
    check "混合区担当候補にする"
    click_button "登録する"

    expect(page).to have_current_path(employees_path)
    expect(page).to have_content("スタッフを登録しました。")
    expect(page).to have_content(employee_name)
    expect(page).to have_content(zone.name)
  end
end
