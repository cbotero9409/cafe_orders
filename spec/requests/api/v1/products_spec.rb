require 'rails_helper'

RSpec.describe "Api::V1::Products", type: :request do
  let(:headers) do
    { "CONTENT_TYPE" => "application/json" }
  end

  describe "GET /api/v1/products" do    
    context "when we request all products" do
      it "returns all the products" do
        create_list(:product, 2)
        create_list(:product, 2, stock: 0)
        create_list(:product, 2, active: false)

        get "/api/v1/products", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json["data"].size).to eq(6)
      end
    end

    context "when we request only for available products" do
      let!(:available_products) { create_list(:product, 5) }
      it "returns only available products" do
        create_list(:product, 2, stock: 0, active: false)

        get "/api/v1/products", params: { scope: "available" }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json["data"].size).to eq(5)

        returned_ids = json["data"].map { |p| p["id"].to_i }
        expect(returned_ids).to match_array(available_products.map(&:id))
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
end
