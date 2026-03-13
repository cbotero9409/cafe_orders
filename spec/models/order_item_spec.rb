require 'rails_helper'

RSpec.describe OrderItem, type: :model do
  subject(:order_item) { create(:order_item) }

  describe "validations" do
    describe "quantity" do
      it { should validate_presence_of(:quantity) }
      it { should validate_numericality_of(:quantity).only_integer.is_greater_than_or_equal_to(1) }
    end

    describe "unit_price" do
      it { should validate_presence_of(:unit_price) }
      it { should validate_numericality_of(:unit_price).only_integer.is_greater_than(0) }
    end

    describe "product_id" do
      it { should validate_uniqueness_of(:product_id).scoped_to(:order_id) }
    end
  end

  describe "relations" do
    it { should belong_to(:product) }
    it { should belong_to(:order) }
  end

  describe "methods" do
    describe "#line_total" do
      let(:order_item) { build(:order_item, quantity: 3, unit_price: 3000) }
      it "validates the line total" do
        expect(order_item.line_total).to eq(9000) 
      end
    end
  end
end
