require 'rails_helper'

RSpec.describe Product, type: :model do
  subject(:product) { create(:product) }

  describe "validations" do
    describe "name" do
      it { should validate_presence_of(:name) }
      it { should validate_length_of(:name).is_at_least(2) }
      it { should validate_uniqueness_of(:name).case_insensitive }
    end

    describe "price" do
      it { should validate_presence_of(:price) }
      it { should validate_numericality_of(:price).only_integer }
      it { should validate_numericality_of(:price).is_greater_than(0) }
    end

    describe "stock" do
      it { should validate_presence_of(:stock) }
      it { should validate_numericality_of(:stock).only_integer }
      it { should validate_numericality_of(:stock).is_greater_than_or_equal_to(0) }
    end

    describe "active" do
      it { should validate_inclusion_of(:active).in_array([ true, false ]) }
    end
  end

  describe "methods" do
    describe "#available?" do
      subject(:available) { product.available? }

      let(:product) { build(:product, active: active, stock: stock) }

      context "when active and stock is positive" do
        let(:active) { true }
        let(:stock)  { 10 }

        it { is_expected.to be true }
      end

      context "when active but stock is zero" do
        let(:active) { true }
        let(:stock)  { 0 }

        it { is_expected.to be false }
      end

      context "when inactive but has stock" do
        let(:active) { false }
        let(:stock)  { 10 }

        it { is_expected.to be false }
      end

      context "when inactive and stock is zero" do
        let(:active) { false }
        let(:stock)  { 0 }

        it { is_expected.to be false }
      end
    end
  end

  describe "scopes" do
    describe "active" do
      subject(:active_products) { Product.active }

      let!(:active_product) { create(:product, active: true) }
      let!(:inactive_product) { create(:product, active: false) }

      it "returns only active products" do
        expect(active_products).to match_array([ active_product ])
      end
    end

    describe "available" do
      subject(:available_products) { Product.available }

      let!(:available_product) { create(:product, active: true, stock: 10) }
      let!(:no_stock) { create(:product, active: true, stock: 0) }
      let!(:inactive) { create(:product, active: false, stock: 10) }

      it "returns only active products with stock" do
        expect(available_products).to match_array([ available_product ])
      end
    end
  end
end
