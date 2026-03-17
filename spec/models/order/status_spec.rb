require 'rails_helper'

RSpec.describe Order, type: :model do
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

    describe "status updating restrictions" do
      context "order is pending" do
        let(:pending_order) { build(:order) }

        it "let update order to paid status" do
          pending_order.pay!
          expect(pending_order.status_paid?).to be true
        end

        it "let update order to cancelled status" do
          pending_order.cancel!
          expect(pending_order.status_cancelled?).to be true
        end

        it "raise error if try to change to refunded status" do
          expect { pending_order.refund! }.to raise_error(RuntimeError)
        end
      end
      
      context "order is paid" do
        let(:paid_order) { build(:order, :paid) }
        it "let update order to refunded status" do
          paid_order.refund!
          expect(paid_order.status_refunded?).to be true
        end

        it "raise error if try to change to paid status" do
          expect { paid_order.pay! }.to raise_error(RuntimeError)
        end

        it "raise error if try to change to cancelled status" do
          expect { paid_order.cancel! }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
