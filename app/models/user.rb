class User < ApplicationRecord
  enum :role, { customer: 0, admin: 1 }, prefix: true # Methods: User.role_customer / User.role_admin

  before_validation :normalize_email

  validates :name, presence: true, length: { minimum: 2 }
  validates :email, presence: true, length: { in: 6..254 }, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
