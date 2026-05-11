require 'rails_helper'

RSpec.describe Orders::SendConfirmationJob, type: :job do
  let(:order) { create(:order) }

  it "enqueues on the default queue" do
    expect {
      described_class.perform_later(order.id)
    }.to have_enqueued_job(described_class).with(order.id).on_queue("default")
  end

  it "performs without error" do
    expect { described_class.perform_now(order.id) }.not_to raise_error
  end
end
