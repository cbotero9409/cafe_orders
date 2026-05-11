class Api::V1::ProductsController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    render json: ProductSerializer.new(products)
  end

  def show
    product = Product.find(params[:id])

    render json: ProductSerializer.new(product)
  end

  private

  def products
    case params[:scope]
    when "active"
      Product.active
    when "available"
      Product.available
    else
      Product.all
    end
  end
end
