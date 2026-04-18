namespace :shift_periods do
  desc "既存のシフト期間に現在の土日・祝日判定を反映する"
  task sync_day_types: :environment do
    total_updated = 0
    updated_periods = 0

    ShiftPeriod.find_each do |shift_period|
      updated_count = shift_period.refresh_day_types!
      next if updated_count.zero?

      total_updated += updated_count
      updated_periods += 1

      puts "shift_period_id=#{shift_period.id} updated_shift_days=#{updated_count}"
    end

    puts "done updated_periods=#{updated_periods} updated_shift_days=#{total_updated}"
  end
end
