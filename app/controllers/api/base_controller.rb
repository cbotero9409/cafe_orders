class Api::BaseController < ActionController::API
  include Devise::Controllers::Helpers

  prepend_before_action :force_json_format
  before_action :authenticate_user!

  def require_admin!
    unless current_user&.role_admin?
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end

  private

  # Devise's failure app redirects for "navigational" formats (see
  # config.navigational_formats) and only returns 401 for non-navigational
  # ones. Clients that omit an `Accept: application/json` header would
  # otherwise resolve to :html and get redirected instead of a 401.
  def force_json_format
    request.format = :json
  end
end
