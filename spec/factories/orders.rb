FactoryBot.define do
  factory :order do
    user
    status { :pending }
    total_amount { 10000 }

    trait :paid do
      status { :paid }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :refunded do
      status { :refunded }
    end
  end
end
