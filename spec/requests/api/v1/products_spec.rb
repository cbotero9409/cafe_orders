require 'rails_helper'

RSpec.describe "Api::V1::Products", type: :request do
  let(:headers) do
    { "CONTENT_TYPE" => "application/json" }
  end

  describe "GET /api/v1/products" do
    context "when we request products without a scope" do
      let!(:available_products) { create_list(:product, 5) }
      it "returns only available products by default" do
        create_list(:product, 2, stock: 0, active: false)

        get "/api/v1/products", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json["data"].size).to eq(5)

        returned_ids = json["data"].map { |p| p["id"].to_i }
        expect(returned_ids).to match_array(available_products.map(&:id))
      end
    end

    context "when we request all products" do
      it "returns all products" do
        create_list(:product, 2)
        create_list(:product, 2, stock: 0)
        create_list(:product, 2, active: false)

        get "/api/v1/products", params: { scope: "all" }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json["data"].size).to eq(6)
      end
    end

    context "when we request only for active products" do
      let!(:active_products) { create_list(:product, 7) }
      it "returns only active products" do
        create_list(:product, 10, stock: 20, active: false)

        get "/api/v1/products", params: { scope: "active" }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json["data"].size).to eq(7)

        returned_ids = json["data"].map { |p| p["id"].to_i }
        expect(returned_ids).to match_array(active_products.map(&:id))
      end
    end
  end

  describe "GET /api/v1/products/:id" do
    let(:product) { create(:product) }
    it "returns an existing product" do
      get "/api/v1/products/#{product.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["data"]["id"].to_i).to eq(product.id)
    end

    it "returns not found when product doesn't exist" do
      get "/api/v1/products/9999", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  shared_examples "admin only" do
    context "when user is not authenticated" do
      it "returns unauthorized" do
        make_request
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is not admin" do
      before { sign_in create(:user) }

      it "returns forbidden" do
        make_request
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/products" do
    let(:valid_params) do
      { product: { name: "Espresso", description: "Strong coffee", price: 350, active: true } }
    end
    let(:make_request) { post "/api/v1/products", params: valid_params.to_json, headers: headers }

    it_behaves_like "admin only"

    context "when user is admin" do
      before { sign_in create(:user, :admin) }

      it "creates the product and returns 201" do
        expect { make_request }.to change(Product, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json["data"]["attributes"]["name"]).to eq("Espresso")
      end

      it "returns unprocessable entity when params are invalid" do
        post "/api/v1/products", params: { product: { name: "" } }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json["errors"]).to be_present
      end
    end
  end

  describe "PATCH /api/v1/products/:id" do
    let(:product) { create(:product) }
    let(:update_params) { { product: { name: "Updated Name", price: 500 } } }
    let(:make_request) { patch "/api/v1/products/#{product.id}", params: update_params.to_json, headers: headers }

    it_behaves_like "admin only"

    context "when user is admin" do
      before { sign_in create(:user, :admin) }

      it "updates the product and returns 200" do
        make_request

        expect(response).to have_http_status(:ok)
        expect(json["data"]["attributes"]["name"]).to eq("Updated Name")
      end

      it "returns unprocessable entity when params are invalid" do
        patch "/api/v1/products/#{product.id}", params: { product: { name: "" } }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json["errors"]).to be_present
      end

      it "returns not found when product does not exist" do
        patch "/api/v1/products/9999", params: update_params.to_json, headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v1/products/:id" do
    let!(:product) { create(:product) }
    let(:make_request) { delete "/api/v1/products/#{product.id}", headers: headers }

    it_behaves_like "admin only"

    context "when user is admin" do
      before { sign_in create(:user, :admin) }

      it "soft-deletes the product and returns 204" do
        make_request

        expect(response).to have_http_status(:no_content)
        expect(product.reload.active).to be false
      end

      it "returns not found when product does not exist" do
        delete "/api/v1/products/9999", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
