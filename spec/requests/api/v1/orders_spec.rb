require 'rails_helper'

RSpec.describe "Api::V1::Orders", type: :request do
  let(:headers) do
    { "CONTENT_TYPE" => "application/json" }
  end

  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "POST /api/v1/orders" do
    let!(:product) { create(:product, price: 1000) }

    let(:params) do
      {
        order: {
          items: [
            { product_id: product.id, quantity: 2 }
          ]
        }
      }
    end    

    context "when request is valid" do
      it "creates an order and returns 201" do
        expect {
          post "/api/v1/orders", params: params.to_json, headers: headers
        }.to change(Order, :count).by(1)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["data"]).to be_present
      end
    end

    context "when product does not exist" do
      let(:params) do
        {
          order: {
            items: [
              { product_id: 9999, quantity: 2 }
            ]
          }
        }
      end

      it "returns 422" do
        post "/api/v1/orders", params: params.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end
  end

  describe "GET /api/v1/orders" do    
    it "returns current user's orders" do
      other_user = create(:user)
      orders = create_list(:order, 2, user: user)
      create_list(:order, 1, user: other_user)

      get "/api/v1/orders", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["data"].size).to eq(2)

      returned_ids = json["data"].map { |o| o["id"].to_i }
      expect(returned_ids).to match_array(orders.map(&:id))
    end
  end

  describe "GET /api/v1/orders/:id" do
    context "access order from current user" do
      it "returns the order" do
        own_order = create(:order, user: user)      

        get "/api/v1/orders/#{own_order.id}", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json["data"]).to have_key("attributes")
        expect(json["data"]).to include("id" => own_order.id.to_s)
      end
    end
    
    context "try access order from other user or that doesn't exist" do
      it "returns 404 when order from other user" do
        other_user = create(:user)
        other_order = create(:order, user: other_user)

        get "/api/v1/orders/#{other_order.id}", headers: headers

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 when order does not exist" do
        get "/api/v1/orders/999999", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
