require 'rails_helper'

RSpec.describe Order, type: :model do
  subject(:order) { build(:order) }

  describe "validations" do
    describe "status" do
      it { should define_enum_for(:status).with_values(pending: 0, paid: 1, cancelled: 2, refunded: 3).with_prefix }
    end
  end

  describe "relations" do
    describe "user belonging" do
      it { should belong_to(:user).required }
    end

    describe "has many order_items" do
      let(:order) { create(:order) }
      let!(:order_item) { create(:order_item, order: order) }

      it { should have_many(:order_items).dependent(:restrict_with_error) }
      it "has order items" do 
        expect(order.reload.order_items).to include(order_item)
      end
    end
  end

  describe "methods" do
    describe "#add_product" do
      let(:order) { create(:order) }
      let!(:new_product) { create(:product) }

      it "adds product to the actual order" do
        order.add_product(new_product, 2)
        expect(order.order_items.exists?(product: new_product)).to be(true)
      end

      it "verifies the quantity of the added product" do
        order.add_product(new_product, 4)
        item = order.order_items.find_by(product: new_product)
        expect(item.quantity).to eq(4)
      end

      it "copies the product price into unit_price" do
        product = create(:product, price: 500)
        order.add_product(product, 2)
        item = order.order_items.find_by(product: product)
        expect(item.unit_price).to eq(500)
      end

      it "increments the quantity of an existing order item" do
        new_item = create(:order_item, order: order, quantity: 2)
        order.add_product(new_item.product, 4)
        expect(new_item.reload.quantity).to eq(6)
      end
    end

    describe "callbacks" do
      describe "before validates calculate total_amount" do
        let(:order) { build(:order, total_amount: 0) }

        it "calculates total_amount before validation" do
          order.order_items.build(quantity: 2, unit_price: 100)
          order.order_items.build(quantity: 1, unit_price: 50)

          order.valid?

          expect(order.total_amount).to eq(250)
        end
      end
    end
  end
end
