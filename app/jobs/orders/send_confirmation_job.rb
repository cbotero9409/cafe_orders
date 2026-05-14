class Orders::SendConfirmationJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    OrderMailer.confirmation(order_id).deliver_now
  end
end
