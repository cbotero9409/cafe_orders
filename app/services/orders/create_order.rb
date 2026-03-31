module Orders
  class CreateOrder < ApplicationService::Base
    def initialize(user:, items:)
      @user = user
      @items = items
    end

    def call
      return failure(["User is required"]) if @user.blank?
      return failure(["Items cannot be empty"]) if @items.blank?

      order = nil

      ActiveRecord::Base.transaction do
        order = Order.new(user: @user)

        @items.each do |item|
          product = Product.find(item[:product_id])

          order.order_items.build(
            product: product,
            quantity: item[:quantity],
            unit_price: product.price
          )
        end

        order.save!
      end

      success(order)

    rescue ActiveRecord::RecordNotFound => e
      failure(["Product not found: #{e.message}"])

    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    def success(order)
      ApplicationService::Result.new(data: order)
    end

    def failure(errors)
      ApplicationService::Result.new(errors: errors)
    end
  end
end
