require 'rails_helper'

RSpec.describe Users::UpdateProfile do
  describe '#call' do
    subject(:result) { described_class.call(user: user, attrs: attrs) }

    let(:user) { create(:user, password: "password123", password_confirmation: "password123") }

    context 'when only the name changes' do
      let(:attrs) { { name: "New Name", email: user.email, password: "", current_password: "" } }

      it 'updates without the current password' do
        expect(result).to be_success
        expect(user.reload.name).to eq("New Name")
      end
    end

    context 'when the email changes' do
      let(:attrs) { { email: "other@example.com", current_password: current_password } }

      context 'without the current password' do
        let(:current_password) { "" }

        it 'fails and keeps the email' do
          expect(result).to be_failure
          expect(result.errors).to be_present
          expect(user.reload.email).not_to eq("other@example.com")
        end
      end

      context 'with a wrong current password' do
        let(:current_password) { "wrong" }

        it 'fails and keeps the email' do
          expect(result).to be_failure
          expect(user.reload.email).not_to eq("other@example.com")
        end
      end

      context 'with the current password' do
        let(:current_password) { "password123" }

        it 'updates the email' do
          expect(result).to be_success
          expect(user.reload.email).to eq("other@example.com")
        end
      end
    end

    context 'when the password changes' do
      let(:attrs) do
        { password: "newpass123", password_confirmation: "newpass123", current_password: current_password }
      end

      context 'without the current password' do
        let(:current_password) { "" }

        it 'fails' do
          expect(result).to be_failure
          expect(user.reload.valid_password?("newpass123")).to be(false)
        end
      end

      context 'with the current password' do
        let(:current_password) { "password123" }

        it 'updates the password' do
          expect(result).to be_success
          expect(user.reload.valid_password?("newpass123")).to be(true)
        end
      end
    end

    context 'when the new data is invalid' do
      let(:attrs) { { name: "A", email: user.email, current_password: "" } }

      it 'fails with validation errors' do
        expect(result).to be_failure
        expect(result.errors).to be_present
      end
    end

    context 'when the user is missing' do
      let(:user) { nil }
      let(:attrs) { { name: "x" } }

      it 'fails' do
        expect(result).to be_failure
      end
    end
  end
end
