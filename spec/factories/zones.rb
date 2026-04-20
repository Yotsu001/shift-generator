FactoryBot.define do
  factory :zone do
    sequence(:name) { |n| "#{Faker::Address.community} #{n}" }
    position { Zone.next_position }
    active { true }
  end
end
