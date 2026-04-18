FactoryBot.define do
  factory :shift_day do
    skip_create

    transient do
      period_start_date { Date.new(2026, 4, 13) }
      period_end_date { period_start_date + 2.days }
    end

    shift_period { create(:shift_period, start_date: period_start_date, end_date: period_end_date) }
    target_date { shift_period.start_date }
    day_type { target_date.present? ? ShiftPeriod.detect_day_type_for(target_date) : :weekday }

    initialize_with do
      if target_date.present?
        shift_period.shift_days.find_or_initialize_by(target_date: target_date).tap do |shift_day|
          shift_day.day_type = day_type
        end
      else
        shift_period.shift_days.new(target_date: target_date, day_type: day_type)
      end
    end

    to_create(&:save!)
  end
end
