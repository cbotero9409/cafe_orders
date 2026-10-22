module Users
  # Updates a user's own profile. The current password is only required to
  # change the email or the password; other fields (e.g. name) can be updated freely.
  class UpdateProfile < ApplicationService::Base
    def initialize(user:, attrs:)
      @user = user
      @attrs = attrs
    end

    def call
      return failure([ "User is required" ]) if @user.blank?

      updated = if sensitive_change?
        @user.update_with_password(@attrs)
      else
        @user.update_without_password(@attrs.except(:current_password))
      end

      updated ? success(@user) : failure(@user.errors.full_messages)
    end

    private

    def sensitive_change?
      @attrs[:password].present? || @attrs[:email].to_s.strip.downcase != @user.email
    end

    def success(user)
      ApplicationService::Result.new(data: user)
    end

    def failure(errors)
      ApplicationService::Result.new(errors: errors)
    end
  end
end
