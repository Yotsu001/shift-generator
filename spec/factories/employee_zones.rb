FactoryBot.define do
  factory :employee_zone do
    association :employee
    association :zone
  end
end
