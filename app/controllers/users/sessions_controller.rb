class Users::SessionsController < Devise::SessionsController
  def destroy
    cart = session[:cart]
    super
    session[:cart] = cart if cart.present?
  end
end
