FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    role { :customer }
    password { "123456" }
    password_confirmation { "123456" }

    trait :admin do
      role { :admin }
    end
  end
end
