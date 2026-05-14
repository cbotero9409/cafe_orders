class OrderMailer < ApplicationMailer
  def confirmation(order_id)
    @order = Order.find(order_id)
    @user = @order.user

    mail(
      to: @user.email,
      subject: "Your order has been confirmed"
    )
  end
end