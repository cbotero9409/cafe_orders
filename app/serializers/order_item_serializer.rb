class OrderItemSerializer
  include JSONAPI::Serializer

  attributes :product_id, :quantity, :unit_price
end