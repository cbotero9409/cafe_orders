class Api::V1::ProductsController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:index, :show]

  before_action :require_admin!, only: [:create, :update, :destroy]

  def index
    render json: ProductSerializer.new(products)
  end

  def show
    product = Product.find(params[:id])

    render json: ProductSerializer.new(product)
  end

  def create
    product = Product.new(product_params)

    if product.save
      render json: ProductSerializer.new(product), status: :created
    else
      render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    product = Product.find(params[:id])

    if product.update(product_params)
      render json: ProductSerializer.new(product)
    else
      render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    product = Product.find(params[:id])
    product.update!(active: false)
    head :no_content
  end

  private

  def product_params
    params.require(:product).permit(:name, :description, :price, :active)
  end

  def products
    case params[:scope]
    when "all"
      Product.all
    when "active"
      Product.active
    else
      Product.available
    end
  end
end
