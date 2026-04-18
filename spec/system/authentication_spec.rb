require "rails_helper"

RSpec.describe "ログイン", type: :system do
  it "ログイン画面からサインインできること" do
    user = create(:user, password: "password123")

    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"

    expect(page).to have_current_path(root_path)
    expect(page).to have_content("ログイン中")
    expect(page).to have_content("#{user.name}さん")
    expect(page).to have_content("ログイン情報")
  end
end
