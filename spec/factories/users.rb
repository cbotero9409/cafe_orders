FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    role { :customer }

    trait :admin do
      role { :admin }
    end
  end
end
