module ShiftGeneration
  class SimpleGenerator
    WEEKDAY_MAX_ASSIGNMENTS_COUNT = 5
    WEEKEND_WORK_TYPES = %w[day_shift night_shift].freeze

    def initialize(shift_period)
      @shift_period = shift_period
      @shift_days   = shift_period.shift_days.includes(:shift_assignments, :leave_requests).order(:target_date)
      @users        = User.includes(:zones).order(:id)
    end

    def call
      Rails.logger.debug "=== SimpleGenerator start shift_period_id=#{shift_period.id} ==="

      created_count = 0

      ActiveRecord::Base.transaction do
        # 1. 先に土日祝勤務を確定
        weekend_or_holiday_shift_days.each do |shift_day|
          Rails.logger.debug "---- weekend/holiday shift_day_id=#{shift_day.id} date=#{shift_day.target_date} day_type=#{shift_day.day_type} ----"

          before_count = shift_day.shift_assignments.count
          assign_weekend_or_holiday(shift_day)
          shift_day.reload
          after_count = shift_day.shift_assignments.count

          delta = after_count - before_count
          created_count += delta

          Rails.logger.debug "[weekend/holiday] date=#{shift_day.target_date} created=#{delta}"
        end

        # 2. 次に代償休を確保
        compensation_created_count = assign_weekend_compensatory_days!
        created_count += compensation_created_count
        Rails.logger.debug "[compensation] created_count=#{compensation_created_count}"

        # 3. 最後に平日勤務を埋める
        weekday_shift_days.each do |shift_day|
          Rails.logger.debug "---- weekday shift_day_id=#{shift_day.id} date=#{shift_day.target_date} day_type=#{shift_day.day_type} ----"

          before_count = shift_day.shift_assignments.count
          assign_for_day(shift_day)
          shift_day.reload
          after_count = shift_day.shift_assignments.count

          delta = after_count - before_count
          created_count += delta

          Rails.logger.debug "[weekday] date=#{shift_day.target_date} created=#{delta}"
        end
      end

      Rails.logger.debug "=== SimpleGenerator end created_count=#{created_count} ==="
      { created_count: created_count }
    end

    private

    attr_reader :shift_period, :shift_days, :users

    def weekend_or_holiday?(shift_day)
      shift_day.saturday? || shift_day.sunday? || holiday?(shift_day)
    end

    # -------------------------
    # 平日割当
    # -------------------------
    def assign_for_day(shift_day)
      assign_mixed_zone_for_day(shift_day)

      created_count = existing_working_assignment_count(shift_day)

      candidate_users_for(shift_day).each do |user|
        break if created_count >= weekday_max_assignments_count

        next if shift_day.leave_request_for(user).present?
        next if shift_day.assignment_for(user).present?

        zone = selectable_zone_for(user)
        next if zone.blank?

        assignment = shift_day.shift_assignments.build(
          user: user,
          work_type: "day_shift",
          zone: zone
        )

        assignment.save!
        created_count += 1

        Rails.logger.debug "[weekday] created assignment_id=#{assignment.id} user_id=#{user.id} zone_name=#{zone.name}"
      end
    end

    # -------------------------
    # 土日祝割当
    # 不足分だけ補完する
    # -------------------------
    def assign_weekend_or_holiday(shift_day)
      current_assignments = shift_day.shift_assignments.where(work_type: WEEKEND_WORK_TYPES)
      current_count = current_assignments.count

      Rails.logger.debug "[holiday] date=#{shift_day.target_date} current_count=#{current_count}"

      return if current_count >= 2

      existing_work_types = current_assignments.pluck(:work_type)
      missing_work_types = WEEKEND_WORK_TYPES - existing_work_types

      Rails.logger.debug "[holiday] existing_work_types=#{existing_work_types.inspect}"
      Rails.logger.debug "[holiday] missing_work_types=#{missing_work_types.inspect}"

      available_users = weekend_candidate_users_for(shift_day)
      Rails.logger.debug "[holiday] available_users=#{available_users.map(&:id).inspect}"
      Rails.logger.debug "[holiday] counts=#{available_users.map { |u| [u.id, weekend_assignment_count(u)] }.inspect}"

      return if available_users.size < missing_work_types.size

      selected_users = select_weekend_users(available_users).first(missing_work_types.size)

      missing_work_types.each_with_index do |work_type, index|
        user = selected_users[index]
        next if user.blank?

        create_weekend_assignment(shift_day, user, work_type)
      end
    end

    def weekend_candidate_users_for(shift_day)
      users.reject do |user|
        shift_day.leave_request_for(user).present? || shift_day.assignment_for(user).present?
      end
    end

    def select_weekend_users(available_users)
      available_users.sort_by { |user| [weekend_assignment_count(user), user.id] }
    end

    def create_weekend_assignment(shift_day, user, work_type)
      Rails.logger.debug "[holiday] creating date=#{shift_day.target_date} user_id=#{user.id} work_type=#{work_type}"

      assignment = shift_day.shift_assignments.create!(
        user: user,
        work_type: work_type
      )

      Rails.logger.debug "[holiday] created assignment_id=#{assignment.id}"
      assignment
    end

    def weekend_assignment_count(user)
      ShiftAssignment.joins(:shift_day)
                     .where(user: user, shift_days: { shift_period_id: shift_period.id })
                     .where(work_type: WEEKEND_WORK_TYPES)
                     .merge(ShiftDay.where(day_type: %w[saturday sunday holiday]))
                     .count
    end

    # -------------------------
    # 混合区割当
    # -------------------------
    def assign_mixed_zone_for_day(shift_day)
      mixed_zone = mixed_zone_record
      return if mixed_zone.blank?
      return if mixed_zone_already_assigned?(shift_day)
      return if existing_working_assignment_count(shift_day) >= weekday_max_assignments_count

      candidates = mixed_zone_candidate_users_for(shift_day)
      Rails.logger.debug "[mixed] date=#{shift_day.target_date} candidates=#{candidates.map(&:id).inspect}"

      user = candidates.first
      return if user.blank?

      assignment = shift_day.shift_assignments.build(
        user: user,
        work_type: "day_shift",
        zone: mixed_zone
      )

      assignment.save!
      Rails.logger.debug "[mixed] created assignment_id=#{assignment.id} user_id=#{user.id}"
    end

    def mixed_zone_already_assigned?(shift_day)
      shift_day.shift_assignments.joins(:zone).exists?(zones: { name: "混合" })
    end

    def mixed_zone_candidate_users_for(shift_day)
      candidates = users.select do |user|
        next false if shift_day.leave_request_for(user).present?
        next false if shift_day.assignment_for(user).present?

        user.zones.exists?(name: "混合")
      end

      candidates.sort_by do |user|
        [mixed_assignment_count(user), user.id]
      end
    end

    def mixed_assignment_count(user)
      ShiftAssignment.joins(:zone, :shift_day)
                     .where(
                       user: user,
                       zones: { name: "混合" },
                       shift_days: { shift_period_id: shift_period.id }
                     )
                     .count
    end

    # -------------------------
    # 土日勤務に対する代償休
    # 土曜勤務 -> off_duty
    # 日曜勤務 -> holiday
    # -------------------------
    def assign_weekend_compensatory_days!
      created_count = 0
      created_count += assign_compensatory_off_duty_for_saturday_work!
      created_count += assign_compensatory_holiday_for_sunday_work!
      created_count
    end

    def assign_compensatory_off_duty_for_saturday_work!
      created_count = 0

      saturday_shift_days.each do |shift_day|
        working_users_on(shift_day).each do |user|
          target_day = find_weekday_for_compensation(
            weekend_shift_day: shift_day,
            user: user,
            reverse: false
          )

          if target_day.blank?
            Rails.logger.debug "[compensation] skip off_duty date=#{shift_day.target_date} user_id=#{user.id} reason=no_available_weekday"
            next
          end

          assign_rest_day(target_day, user, "off_duty")
          created_count += 1
        end
      end

      created_count
    end

    def assign_compensatory_holiday_for_sunday_work!
      created_count = 0

      sunday_shift_days.each do |shift_day|
        working_users_on(shift_day).each do |user|
          target_day = find_weekday_for_compensation(
            weekend_shift_day: shift_day,
            user: user,
            reverse: true
          )

          if target_day.blank?
            Rails.logger.debug "[compensation] skip holiday date=#{shift_day.target_date} user_id=#{user.id} reason=no_available_weekday"
            next
          end

          assign_rest_day(target_day, user, "holiday")
          created_count += 1
        end
      end

      created_count
    end

    def saturday_shift_days
      shift_days.select(&:saturday?)
    end

    def sunday_shift_days
      shift_days.select(&:sunday?)
    end

    def working_users_on(shift_day)
      shift_day.shift_assignments
               .where(work_type: WEEKEND_WORK_TYPES)
               .includes(:user)
               .map(&:user)
    end

    def find_weekday_for_compensation(weekend_shift_day:, user:, reverse: false)
      candidate_days = compensation_candidate_days_for(weekend_shift_day)
      candidate_days = candidate_days.reverse if reverse

      candidate_days.find do |day|
        next false if day.assignment_for(user).present?
        next false if day.leave_request_for(user).present?

        true
      end
    end

    def compensation_candidate_days_for(weekend_shift_day)
      week_start = weekend_shift_day.target_date.beginning_of_week(:monday)
      week_end   = weekend_shift_day.target_date.end_of_week(:monday)

      shift_days.select do |day|
        day.target_date >= week_start &&
          day.target_date <= week_end &&
          !weekend_or_holiday?(day)
      end
    end

    def assign_rest_day(shift_day, user, work_type)
      assignment = shift_day.shift_assignments.create!(
        user: user,
        work_type: work_type
      )

      Rails.logger.debug "[compensation] created assignment_id=#{assignment.id} date=#{shift_day.target_date} user_id=#{user.id} work_type=#{work_type}"
      assignment
    end

    # -------------------------
    # 共通
    # -------------------------
    def candidate_users_for(shift_day)
      users.reject do |user|
        shift_day.leave_request_for(user).present? || shift_day.assignment_for(user).present?
      end
    end

    def selectable_zone_for(user)
      user.zones
          .where.not(name: "混合")
          .order(:position)
          .first
    end

    def existing_working_assignment_count(shift_day)
      shift_day.shift_assignments.where(work_type: WEEKEND_WORK_TYPES).count
    end

    def weekday_max_assignments_count
      WEEKDAY_MAX_ASSIGNMENTS_COUNT
    end

    def mixed_zone_record
      @mixed_zone_record ||= Zone.find_by(name: "混合")
    end

    def weekend_or_holiday_shift_days
      shift_days.select { |day| weekend_or_holiday?(day) }
    end

    def weekday_shift_days
      shift_days.reject { |day| weekend_or_holiday?(day) }
    end
  end
end