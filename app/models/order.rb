class Order < ApplicationRecord
  enum :status, { pending: 0, paid: 1, cancelled: 2, refunded: 3 }, prefix: true

  belongs_to :user
  has_many :order_items, dependent: :restrict_with_error

  validates :total_amount, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def recalculate_total!
    update!(total_amount: order_items.sum("quantity * unit_price"))
  end

  def pay!
    raise "Order already paid" unless status_pending?

    update!(status: :paid)
  end

  def cancel!
    raise "Cannot cancel paid order" unless status_pending?

    update!(status: :cancelled)
  end

  def refund!
    raise "Only paid orders can be refunded" unless status_paid?

    update!(status: :refunded)
  end

  def add_product(product, quantity)
    item = order_items.find_by(product: product)

    if item
      item.increment!(:quantity, quantity)
    else
      order_items.create!(
        product: product,
        quantity: quantity,
        unit_price: product.price
      )
    end
  end
end
