require 'rails_helper'

RSpec.describe "Api::V1::Orders", type: :request do
  describe "POST /api/v1/orders" do
    let(:user) { create(:user) }
    let!(:product) { create(:product, price: 1000) }

    let(:headers) do
      { "CONTENT_TYPE" => "application/json" }
    end

    let(:params) do
      {
        order: {
          items: [
            { product_id: product.id, quantity: 2 }
          ]
        }
      }
    end

    before do
      sign_in user
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
end