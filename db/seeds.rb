# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Development users (password for all: "password123")
[
  { name: "Admin User",     email: "admin@example.com",  role: :admin },
  { name: "Customer One",   email: "customer1@example.com", role: :customer },
  { name: "Customer Two",   email: "customer2@example.com", role: :customer }
].each do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |user|
    user.name = attrs[:name]
    user.role = attrs[:role]
    user.password = "password123"
    user.password_confirmation = "password123"
  end
end
