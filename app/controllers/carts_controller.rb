class CartsController < ApplicationController
  def show
    product_ids = cart_session.keys.map(&:to_i)
    products_by_id = Product.where(id: product_ids).index_by { |p| p.id.to_s }

    @cart_items = cart_session.filter_map do |product_id, qty|
      product = products_by_id[product_id]
      next unless product
      { product: product, quantity: qty, subtotal: product.price * qty }
    end

    @total = @cart_items.sum { |item| item[:subtotal] }
  end

  def add
    qty = [params[:quantity].to_i, 1].max
    cart_session[params[:product_id]] = (cart_session[params[:product_id]] || 0) + qty
    redirect_back_or_to products_path
  end

  def remove
    cart_session.delete(params[:product_id])
    redirect_to cart_path
  end

  def update
    qty = params[:quantity].to_i
    if qty <= 0
      cart_session.delete(params[:product_id])
    else
      cart_session[params[:product_id]] = qty
    end
    redirect_to cart_path
  end

  private

  def cart_session
    session[:cart] ||= {}
  end
end
