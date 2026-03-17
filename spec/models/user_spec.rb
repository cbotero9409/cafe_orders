require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "validations" do
    describe "name" do
      it { should validate_presence_of(:name) }
      it { should validate_length_of(:name).is_at_least(2) }
    end

    describe "email" do
      it { should validate_presence_of(:email) }
      it { should validate_length_of(:email).is_at_least(6).is_at_most(254) }      
      it { should validate_uniqueness_of(:email).case_insensitive }      
      it "rejects invalid emails" do
        invalid_emails = [ "invalid", "test@", "@test.com" ]

        invalid_emails.each do |email|
          user.email = email
          expect(user).not_to be_valid
        end
      end
    end

    describe "role" do
      it { should define_enum_for(:role).with_values(customer: 0, admin: 1).with_prefix }
      
      describe "role behavior" do
        let(:customer) { build(:user) }
        let(:admin) { build(:user, :admin) }

        it "identifies a customer" do
          expect(customer.role_customer?).to be true
        end

        it "identifies an admin" do
          expect(admin.role_admin?).to be true
        end
        it "defaults role to customer" do
          customer.email = nil
          expect(build(:user).role).to eq("customer")
        end
      end
    end
  end

  describe "callbacks" do
    describe "#normalize_email" do
      it "downcases and strips email before validation" do
        user.email = "  TEST@Example.COM  "
        user.validate
        expect(user.email).to eq("test@example.com")
      end
    end
  end
end
