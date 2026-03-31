require 'rails_helper'

RSpec.describe Orders::CreateOrder do
  describe '#call' do
    subject(:result) { described_class.call(user: user, items: items) }

    let(:user) { create(:user) }

    let!(:product1) { create(:product, price: 1000) }
    let!(:product2) { create(:product, price: 2000) }

    let(:items) do
      [
        { product_id: product1.id, quantity: 2 },
        { product_id: product2.id, quantity: 1 }
      ]
    end

    describe "service success" do
      context 'when everything is valid' do
        it 'creates an order with order_items and total_amount' do
          expect { result }.to change(Order, :count).by(1)
            .and change(OrderItem, :count).by(2)

          expect(result).to be_success

          order = result.data
          expect(order).to be_present
          expect(order.user).to eq(user)
          expect(order.order_items.size).to eq(2)
          expect(order.total_amount).to eq(2 * 1000 + 1 * 2000)
        end
      end
    end

    describe "service failure" do
      context 'when a product does not exist' do
        let(:items) do
          [ { product_id: 9999, quantity: 2 } ]
        end

        it 'fails, does not create the order and returns error' do
          expect { result }.not_to change { [ Order.count, OrderItem.count ] }
          expect(result).to be_failure
          expect(result.errors).to be_present
          expect(result.data).to be_nil
        end
      end

      context 'when order is invalid' do
        let(:user) { nil }

        it 'fails and returns validation errors' do
          expect { result }.not_to change { [ Order.count, OrderItem.count ] }
          expect(result).to be_failure
          expect(result.errors).to be_present
          expect(result.data).to be_nil
        end
      end
    end    
  end
end
