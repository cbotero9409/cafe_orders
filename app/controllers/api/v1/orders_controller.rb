class Api::V1::OrdersController < Api::BaseController
  # before_action :require_admin!, only: [:create]

  def index
    orders = current_user.orders.includes(:order_items)

    render json: OrderSerializer.new(orders)
  end

  def show
    order = current_user.orders.includes(:order_items).find(params[:id])

    render json: OrderSerializer.new(order, include: [ :order_items ])
  end
  
  def create
    result = Orders::CreateOrder.call(
      user: current_user,
      items: order_params[:items]
    )

    if result.success?
      render json: OrderSerializer.new(result.data), status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  private

    def order_params
      params.require(:order).permit(items: [ :product_id, :quantity ])
    end
end
