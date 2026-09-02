class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :cart_count

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end

  def cart_count
    (session[:cart] || {}).values.sum
  end

  def require_admin!
    unless current_user&.role_admin?
      redirect_to root_path, alert: "You are not authorized to perform this action."
    end
  end
end
