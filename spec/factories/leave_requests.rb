FactoryBot.define do
  factory :leave_request do
    association :shift_day
    employee { create(:employee, user: shift_day.shift_period.user) }
    note { Faker::Lorem.sentence(word_count: 4) }
  end
end
