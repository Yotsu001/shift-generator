module ShiftGeneration
  class SimpleGenerator
    def initialize(shift_period)
      @shift_period = shift_period
      @shift_days   = shift_period.shift_days.includes(:shift_assignments, :leave_requests).order(:target_date)
      @users        = User.includes(:zones).order(:id)
    end

    def call
      ActiveRecord::Base.transaction do
        target_shift_days.each do |shift_day|
          assign_for_day(shift_day)
        end
      end
    end

    private

    attr_reader :shift_period, :shift_days, :users

    def target_shift_days
      shift_days.select do |shift_day|
        !shift_day.saturday? && !shift_day.sunday? && !shift_day.holiday?
      end
    end

    def assign_for_day(shift_day)
      assigned_zone_ids = existing_zone_ids(shift_day)

      candidate_users_for(shift_day).each do |user|
        next if shift_day.assignment_for(user).present?
        next if shift_day.leave_request_for(user).present?

        zone = selectable_zone_for(user, assigned_zone_ids)
        next if zone.blank?

        assignment = shift_day.shift_assignments.build(
          user: user,
          work_type: "day_shift",
          zone: zone
        )

        if assignment.save
          assigned_zone_ids << zone.id
        end
      end
    end

    def candidate_users_for(shift_day)
      users.reject do |user|
        shift_day.leave_request_for(user).present? || shift_day.assignment_for(user).present?
      end
    end

    def existing_zone_ids(shift_day)
      shift_day.shift_assignments.where.not(zone_id: nil).pluck(:zone_id)
    end

    def selectable_zone_for(user, assigned_zone_ids)
      user.zones
          .order(:position)
          .detect { |zone| !assigned_zone_ids.include?(zone.id) }
    end
  end
end