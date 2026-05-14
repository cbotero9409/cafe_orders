class Api::V1::AuthController < Api::BaseController
  skip_before_action :authenticate_user!, only: [ :signup, :login ]

  def signup
    user = User.new(signup_params)

    if user.save
      sign_in(user)
      render json: { user: user }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email]&.downcase)

    if user&.valid_password?(params[:password])
      sign_in(user)
      render json: { user: user }, status: :ok
    else
      render json: { errors: [ "Invalid email or password" ] }, status: :unauthorized
    end
  end

  def logout
    sign_out(:user)
    head :no_content
  end

  def me
    render json: { user: current_user }
  end

  private

    def signup_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
end
