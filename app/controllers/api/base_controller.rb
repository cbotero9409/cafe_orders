class Api::BaseController < ActionController::API
  include Devise::Controllers::Helpers

  before_action :authenticate_user!

  def require_admin!
    unless current_user&.role_admin?
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end
end