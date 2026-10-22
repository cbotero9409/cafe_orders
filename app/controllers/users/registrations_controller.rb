class Users::RegistrationsController < Devise::RegistrationsController
  # Users with orders can't be deleted (orders are financial records).
  before_action :block_account_deletion, only: :destroy

  protected

  def update_resource(resource, params)
    Users::UpdateProfile.call(user: resource, attrs: params).success?
  end

  def after_update_path_for(_resource)
    profile_path
  end

  private

  def block_account_deletion
    redirect_to profile_path, alert: "Accounts can't be deleted."
  end
end
