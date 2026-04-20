require "rails_helper"

RSpec.describe "シフト期間管理", type: :system do
  it "シフト期間を作成して詳細画面を確認できること" do
    user = create(:user, password: "password123")
    period_name = Faker::Lorem.words(number: 2).join(" ")

    login_as_user(user)
    visit new_shift_period_path

    fill_in "名称", with: period_name
    fill_in "開始日", with: "2026-05-01"
    fill_in "終了日", with: "2026-05-03"
    click_button "作成する"

    expect(page).to have_current_path(%r{/shift_periods/\d+})
    expect(page).to have_content("シフト期間を作成しました")
    expect(page).to have_content("シフト期間詳細")
    expect(page).to have_content(period_name)
    expect(page).to have_content("2026-05-01")
    expect(page).to have_content("2026-05-03")
    expect(page).to have_content("シフト表")
  end

  it "確定済みシフト期間の詳細画面では編集操作が表示されないこと" do
    user = create(:user, password: "password123")
    shift_period = create(:shift_period, user: user, status: :locked)

    login_as_user(user)
    visit shift_period_path(shift_period)

    expect(page).to have_content("このシフト期間は確定済みのため、詳細画面では閲覧のみ可能です。")
    expect(page).not_to have_button("自動生成")
    expect(page).not_to have_button("リセット")
    expect(page).not_to have_link("編集")
  end
end
