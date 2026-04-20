module SystemHelpers
  def login_via_ui(user, password: user.password)
    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: password
    click_button "ログイン"
  end

  def login_as_user(user)
    login_as(user, scope: :user)
  end
end
