class ProductsController < ApplicationController
  before_action :require_admin!, only: [ :new, :create, :edit, :update, :destroy ]
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]

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
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to product_path(@product), notice: "Product created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to product_path(@product), notice: "Product updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.update!(active: false)
    redirect_to products_path, notice: "Product deactivated."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to products_path, alert: "Product not found."
  end

  def product_params
    params.require(:product).permit(:name, :description, :price, :stock, :active)
  end

  def base_scope
    case @filter
    when "active" then Product.active.order(PRIORITY_ORDER)
    when "all"    then Product.all.order(PRIORITY_ORDER)
    else               Product.available.order(:name)
    end
  end
end
