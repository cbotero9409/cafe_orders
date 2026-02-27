" It is used when I need the same object for my tests"
FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    description { "This is our product." }
    price { 100 }
    stock { 10 }
    active { true }
  end
end
