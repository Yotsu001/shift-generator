FactoryBot.define do
  factory :shift_assignment do
    association :shift_day
    employee { create(:employee, :with_zone, user: shift_day.shift_period.user) }
    zone { employee&.zones&.first }
    work_type { :day_shift }
  end
end
