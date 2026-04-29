require 'rails_helper'

RSpec.describe "Api::V1::Auth", type: :request do
  let(:headers) do
    { "CONTENT_TYPE" => "application/json" }
  end

  describe "POST /api/v1/auth/signup" do
    let(:params) do
      {
        user: {
          name: "Camilooo",
          email: "cbotero@test.com",
          password: "12345678",
          password_confirmation: "12345678"
        }
      }
    end

    context "when is valid" do
      it "creates an user and returns 201" do
        expect {
          post "/api/v1/auth/signup", params: params.to_json, headers: headers
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json["user"]).to be_present
        expect(json["user"]["email"]).to eq(params[:user][:email])
        expect(json["user"]["name"]).to eq(params[:user][:name])
        expect(json["user"]).not_to have_key("encrypted_password")
      end
    end

    context "when is invalid" do
      it "returns 422 and errors" do
        params[:user][:email] = "fail"
        post "/api/v1/auth/signup", params: params.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json["errors"]).to be_present
      end
    end
  end

  describe "POST /api/v1/auth/login" do
    let(:password) { "password123" }
    let(:user) { create(:user, password: password, password_confirmation: password) }

    context "when is valid" do
      let(:params) { { email: user.email, password: "password123" } }
      it "login succesfully and returns 200" do
        post "/api/v1/auth/login", params: params.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json["user"]).to be_present
        expect(json["user"]).not_to have_key("encrypted_password")
      end
    end

    context "when is invalid" do
      let(:params) { { email: user.email, password: "wrongpass" } }
      it "returns 401 unauthorized status" do
        post "/api/v1/auth/login", params: params.to_json, headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(json["errors"]).to be_present
      end
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    it "logs out the user and prevents access to protected endpoint" do
      user = create(:user)
      sign_in user

      delete "/api/v1/auth/logout"

      expect(response).to have_http_status(:no_content)

      get "/api/v1/auth/me"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/me" do
    it "returns the current user" do
      user = create(:user)
      sign_in user

      get "/api/v1/auth/me"

      expect(json["user"]["email"]).to eq(user.email)
      expect(json["user"]).not_to have_key("encrypted_password")
    end

    it "returns unauthorized when not logged in" do
      get "/api/v1/auth/me"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
