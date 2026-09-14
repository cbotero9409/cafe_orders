class ProductsController < ApplicationController
  PRIORITY_ORDER = Arel.sql(
    "CASE WHEN active = true AND stock > 0 THEN 0 " \
    "     WHEN active = true AND stock = 0 THEN 1 " \
    "     ELSE 2 END, name ASC"
  )

  def index
    @filter = params[:filter] || "available"
    @q      = params[:q].to_s.strip

    @products = base_scope
    @products = @products.where("name ILIKE ?", "%#{@q}%") if @q.present?
  end

  def show
    @product = Product.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to products_path, alert: "Product not found."
  end

  private

  def base_scope
    case @filter
    when "active" then Product.active.order(PRIORITY_ORDER)
    when "all"    then Product.all.order(PRIORITY_ORDER)
    else               Product.available.order(:name)
    end
  end
end
