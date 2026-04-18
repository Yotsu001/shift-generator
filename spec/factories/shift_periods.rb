FactoryBot.define do
  factory :shift_period do
    association :user
    sequence(:name) { |n| "#{Faker::Lorem.words(number: 2).join(' ')} #{n}" }
    start_date { Date.new(2026, 4, 13) }
    end_date { start_date + 2.days }
    status { :draft }
  end
end
