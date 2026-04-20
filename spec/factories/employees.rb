FactoryBot.define do
  factory :employee do
    association :user
    sequence(:name) { |n| "#{Faker::Name.name} #{n}" }
    display_order { 0 }
    active { true }
    mixed_zone_enabled { false }
    mixed_zone_preferred { false }
    weekend_work_enabled { true }
    primary_zone { nil }

    trait :with_zone do
      transient do
        assignable_zone { association(:zone) }
      end

      after(:create) do |employee, evaluator|
        employee.zones << evaluator.assignable_zone unless employee.zones.exists?(evaluator.assignable_zone.id)
        employee.update!(primary_zone: evaluator.assignable_zone)
      end
    end
  end
end
