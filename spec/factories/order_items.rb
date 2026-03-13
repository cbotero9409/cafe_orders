FactoryBot.define do
  factory :order_item do
    order
    product
    quantity { 2 }
    unit_price { 2000 }
  end
end
