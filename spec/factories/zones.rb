FactoryBot.define do
  factory :zone do
    sequence(:name) { |n| "#{Faker::Address.community} #{n}" }
    sequence(:position)
    active { true }
  end
end
