FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "#{Faker::Internet.username(specifier: 6..10)}#{n}@example.com" }
    password { "password" }
    name { Faker::Name.name }
    admin { false }
  end
end
