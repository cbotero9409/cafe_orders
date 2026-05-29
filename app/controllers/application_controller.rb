class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :cart_count

  private

  def cart_count
    (session[:cart] || {}).values.sum
  end
end
