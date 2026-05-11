class Orders::SendConfirmationJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find(order_id)

    # for now just simulate
    Rails.logger.info("Sending confirmation for Order #{order.id}")
  end
end