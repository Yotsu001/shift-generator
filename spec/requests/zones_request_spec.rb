require "rails_helper"

RSpec.describe "Zones", type: :request do
  describe "認証" do
    it "未ログイン時は区一覧からログイン画面へ遷移すること" do
      get zones_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "区管理" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "区一覧の各行に編集画面への遷移先が含まれること" do
      zone = create(:zone)

      get zones_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(data-href="#{edit_zone_path(zone)}"))
    end
  end
end
