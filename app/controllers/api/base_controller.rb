class Api::BaseController < ActionController::API
  private

  def current_user
    # temporary placeholder (later replaced by Devise or JWT)
    nil
  end
end