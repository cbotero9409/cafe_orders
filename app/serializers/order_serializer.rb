# app/serializers/order_serializer.rb
class OrderSerializer
  include JSONAPI::Serializer

  attributes :total_amount, :status, :created_at

  has_many :order_items, serializer: OrderItemSerializer
end
