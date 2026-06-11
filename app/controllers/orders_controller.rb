class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = current_user.orders.includes(order_items: :product).order(created_at: :desc)
  end

  def create
    items = cart_items_from_session

    if items.empty?
      redirect_to cart_path, alert: "Your cart is empty."
      return
    end

    result = Orders::CreateOrder.call(user: current_user, items: items)

    if result.success?
      session.delete(:cart)
      redirect_to order_path(result.data), notice: "Order placed successfully!"
    else
      redirect_to cart_path, alert: result.errors.join(", ")
    end
  end

  def show
    @order = current_user.orders.includes(order_items: :product).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Order not found."
  end

  private

  def cart_items_from_session
    (session[:cart] || {}).map do |product_id, quantity|
      { product_id: product_id.to_i, quantity: quantity }
    end
  end
end
