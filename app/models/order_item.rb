class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :product_id, uniqueness: { scope: :order_id }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 } 
  validates :unit_price, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def line_total
    quantity * unit_price
  end
end
