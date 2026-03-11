require 'rails_helper'

RSpec.describe Order, type: :model do
  subject(:order) { build(:order) }

  describe "validations" do
    describe "total_amount" do
      it { should validate_presence_of(:total_amount) }
      it { should validate_numericality_of(:total_amount).only_integer.is_greater_than_or_equal_to(0) }
    end

    describe "status" do
      it { should define_enum_for(:status).with_values(pending: 0, paid: 1, cancelled: 2, refunded: 3).with_prefix }
      
      describe "status behavior" do
        let(:pending_order) { build(:order) }
        let(:paid_order) { build(:order, :paid) }
        let(:cancelled_order) { build(:order, :cancelled) }
        let(:refunded_order) { build(:order, :refunded) }

        it "identifies a pending order and default" do
          expect(pending_order.status_pending?).to be true
        end
        it "identifies a paid order" do
          expect(paid_order.status_paid?).to be true
        end
        it "identifies a cancelled order" do
          expect(cancelled_order.status_cancelled?).to be true
        end
        it "identifies a refunded order" do
          expect(refunded_order.status_refunded?).to be true
        end
      end
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
        expect(order.order_items).to include(order_item)
      end
    end
  end

  describe "methods" do
    describe "#recalculate_total!" do
      let(:order) { create(:order, total_amount: 0) }

      before do
        create(:order_item, order: order, quantity: 2, unit_price: 100)
        create(:order_item, order: order, quantity: 1, unit_price: 50)
      end

      it "recalculates the total_amount from order_items" do
        order.recalculate_total!
        expect(order.reload.total_amount).to eq(250)
      end
    end

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
        new_item = create(:order_item, order: order, quantity: 2 )
        order.add_product(new_item.product, 4)
        expect(new_item.reload.quantity).to eq(6)
      end
    end
  end
end
