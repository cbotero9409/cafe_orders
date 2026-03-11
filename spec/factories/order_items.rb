FactoryBot.define do
  factory :order_item do
    order
    product
    quantity { 1 }
    unit_price { 20 }
  end
end
