module OrdersHelper
  STATUS_BADGE_CLASSES = {
    "pending"   => "bg-amber-100 text-amber-800",
    "paid"      => "bg-green-100 text-green-800",
    "cancelled" => "bg-stone-100 text-stone-600",
    "refunded"  => "bg-stone-100 text-stone-600"
  }.freeze

  def order_status_badge(order)
    tag.span order.status.capitalize,
             class: "inline-block text-xs font-medium px-2 py-0.5 rounded-full #{STATUS_BADGE_CLASSES[order.status]}"
  end
end
