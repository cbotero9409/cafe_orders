class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user          = current_user
    @orders_count  = @user.orders.count
    @total_spent   = @user.orders.sum(:total_amount)
    @recent_orders = @user.orders.includes(:order_items).order(created_at: :desc).limit(3)
  end
end
