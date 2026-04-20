module ShiftGeneration
  class SimpleGenerator
    WEEKEND_AUTO_WORK_TYPES = %w[day_shift middle_shift].freeze

    def initialize(shift_period)
      @shift_period = shift_period
      @shift_days   = shift_period.shift_days.includes(:shift_assignments, :leave_requests).order(:target_date)
      @employees    = shift_period.user.employees.active_ordered
    end

    def call
      Rails.logger.debug "=== SimpleGenerator start shift_period_id=#{shift_period.id} ==="

      created_count = 0

      ActiveRecord::Base.transaction do
        weekend_or_holiday_shift_days.each do |shift_day|
          Rails.logger.debug "---- weekend/holiday shift_day_id=#{shift_day.id} date=#{shift_day.target_date} day_type=#{shift_day.day_type} ----"

          before_count = shift_day.shift_assignments.count
          assign_weekend_or_holiday(shift_day)
          assign_default_weekend_rest_days(shift_day)
          shift_day.reload
          after_count = shift_day.shift_assignments.count

          created_count += (after_count - before_count)
        end

        compensation_created_count = assign_weekend_compensatory_days!
        created_count += compensation_created_count
        Rails.logger.debug "[compensation] created_count=#{compensation_created_count}"

        weekday_shift_days.each do |shift_day|
          Rails.logger.debug "---- weekday shift_day_id=#{shift_day.id} date=#{shift_day.target_date} day_type=#{shift_day.day_type} ----"

          before_count = shift_day.shift_assignments.count
          assign_for_day(shift_day)
          shift_day.reload
          after_count = shift_day.shift_assignments.count

          created_count += (after_count - before_count)
        end
      end

      Rails.logger.debug "=== SimpleGenerator end created_count=#{created_count} ==="
      { created_count: created_count }
    end

    private

    attr_reader :shift_period, :shift_days, :employees

    def weekend_or_holiday?(shift_day)
      shift_day.saturday? || shift_day.sunday? || shift_day.holiday?
    end

    # -------------------------
    # 平日割当
    # -------------------------
    def assign_for_day(shift_day)
      assign_middle_shift_for_day(shift_day)
      zone_counts = regular_zone_assignment_counts_for(shift_day)
      assign_must_staff_for_day(shift_day, zone_counts)
      assign_regular_zones_for_day(shift_day, zone_counts)
    end

    def assign_regular_zones_for_day(shift_day, zone_counts)
      candidate_employees_for(shift_day).each do |employee|
        zone = selectable_zone_for(employee, zone_counts)
        next if zone.blank?

        assignment = shift_day.shift_assignments.build(
          employee: employee,
          work_type: "day_shift",
          zone: zone
        )

        assignment.save!
        increment_weekday_assignment_count(employee)
        zone_counts[zone.id] += 1

        Rails.logger.debug "[weekday] created assignment_id=#{assignment.id} employee_id=#{employee.id} zone_name=#{zone.name} work_type=#{assignment.work_type}"
      end
    end

    def assign_must_staff_for_day(shift_day, zone_counts)
      return if must_staff_assigned_on?(shift_day)

      employee = must_staff_candidate_employees_for(shift_day).find do |candidate|
        selectable_zone_for(candidate, zone_counts).present?
      end
      return if employee.blank?

      zone = selectable_zone_for(employee, zone_counts)
      return if zone.blank?

      assignment = shift_day.shift_assignments.build(
        employee: employee,
        work_type: "day_shift",
        zone: zone
      )

      assignment.save!
      increment_weekday_assignment_count(employee)
      zone_counts[zone.id] += 1

      Rails.logger.debug "[weekday-must] created assignment_id=#{assignment.id} employee_id=#{employee.id} zone_name=#{zone.name} work_type=#{assignment.work_type}"
    end

    # -------------------------
    # 土日祝割当
    # -------------------------
    def assign_weekend_or_holiday(shift_day)
      current_assignments = shift_day.shift_assignments.where(work_type: WEEKEND_AUTO_WORK_TYPES)
      return if current_assignments.count >= 2

      existing_work_types = current_assignments.pluck(:work_type)
      missing_work_types = WEEKEND_AUTO_WORK_TYPES - existing_work_types

      available_employees = weekend_candidate_employees_for(shift_day)
      return if available_employees.size < missing_work_types.size

      selected_employees = select_weekend_employees(available_employees, shift_day).first(missing_work_types.size)

      missing_work_types.each_with_index do |work_type, index|
        employee = selected_employees[index]
        next if employee.blank?

        create_weekend_assignment(shift_day, employee, work_type)
      end
    end

    def assign_default_weekend_rest_days(shift_day)
      work_type = default_weekend_rest_work_type_for(shift_day)
      return if work_type.blank?

      employees.each do |employee|
        next if shift_day.leave_request_for(employee).present?
        next if shift_day.assignment_for(employee).present?

        assign_rest_day(shift_day, employee, work_type)
      end
    end

    def default_weekend_rest_work_type_for(shift_day)
      if shift_day.saturday?
        "saturday_off"
      elsif shift_day.sunday?
        "sunday_off"
      elsif shift_day.holiday?
        "national_holiday"
      end
    end

    def weekend_candidate_employees_for(shift_day)
      employees.reject do |employee|
        !employee.weekend_work_enabled ||
          shift_day.leave_request_for(employee).present? ||
          shift_day.assignment_for(employee).present?
      end
    end

    def select_weekend_employees(available_employees, shift_day)
      available_employees.sort_by do |employee|
        [
          weekend_assignment_count(employee),
          weekly_assignment_count(employee, shift_day),
          employee.id
        ]
      end
    end

    def create_weekend_assignment(shift_day, employee, work_type)
      shift_day.shift_assignments.create!(
        employee: employee,
        work_type: work_type
      )
    end

    def weekend_assignment_count(employee)
      ShiftAssignment.joins(:shift_day)
                     .where(employee: employee, shift_days: { shift_period_id: shift_period.id })
                     .where(work_type: WEEKEND_AUTO_WORK_TYPES)
                     .merge(ShiftDay.where(day_type: %w[saturday sunday holiday]))
                     .count
    end

    # -------------------------
    # 中勤割当
    # -------------------------
    def assign_middle_shift_for_day(shift_day)
      return if middle_shift_already_assigned?(shift_day)

      employee = middle_shift_candidate_employees_for(shift_day).first
      return if employee.blank?

      assignment = shift_day.shift_assignments.build(
        employee: employee,
        work_type: "middle_shift"
      )

      assignment.save!
      increment_weekday_assignment_count(employee)

      Rails.logger.debug "[middle] created assignment_id=#{assignment.id} employee_id=#{employee.id} work_type=#{assignment.work_type}"
    end

    def middle_shift_already_assigned?(shift_day)
      shift_day.shift_assignments.exists?(work_type: "middle_shift")
    end

    def middle_shift_candidate_employees_for(shift_day)
      candidates = employees.select(&:mixed_zone_preferred)
                            .reject { |employee| unavailable_for_work_assignment?(shift_day, employee) }

      candidates.sort_by do |employee|
        [employee.must_staff ? 0 : 1, middle_shift_assignment_count(employee), employee.id]
      end
    end

    def middle_shift_assignment_count(employee)
      ShiftAssignment.joins(:shift_day)
                     .where(employee: employee, shift_days: { shift_period_id: shift_period.id })
                     .where(work_type: "middle_shift")
                     .where.not(shift_days: { day_type: %w[saturday sunday holiday] })
                     .count
    end

    # -------------------------
    # 代償休
    # -------------------------
    def assign_weekend_compensatory_days!
      assign_compensatory_sunday_off_for_sunday_work! +
        assign_compensatory_saturday_off_for_saturday_work! +
        assign_compensatory_national_holiday_for_holiday_work!
    end

    def assign_compensatory_saturday_off_for_saturday_work!
      created_count = 0

      saturday_shift_days.each do |shift_day|
        working_employees_on(shift_day).each do |employee|
          target_day = find_weekday_for_compensation(
            weekend_shift_day: shift_day,
            employee: employee,
            reverse: false,
            work_type: "saturday_off"
          )

          next if target_day.blank?

          assign_rest_day(target_day, employee, "saturday_off")
          created_count += 1
        end
      end

      created_count
    end

    def assign_compensatory_sunday_off_for_sunday_work!
      created_count = 0

      sunday_shift_days.each do |shift_day|
        working_employees_on(shift_day).each do |employee|
          target_day = find_weekday_for_compensation(
            weekend_shift_day: shift_day,
            employee: employee,
            reverse: true,
            work_type: "sunday_off"
          )

          next if target_day.blank?

          assign_rest_day(target_day, employee, "sunday_off")
          created_count += 1
        end
      end

      created_count
    end

    def assign_compensatory_national_holiday_for_holiday_work!
      created_count = 0

      holiday_shift_days.each do |shift_day|
        working_employees_on(shift_day).each do |employee|
          target_day = find_weekday_for_compensation(
            weekend_shift_day: shift_day,
            employee: employee,
            reverse: false,
            work_type: "national_holiday"
          )

          next if target_day.blank?

          assign_rest_day(target_day, employee, "national_holiday")
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

    def holiday_shift_days
      shift_days.select(&:holiday?)
    end

    def working_employees_on(shift_day)
      shift_day.shift_assignments
               .where(work_type: WEEKEND_AUTO_WORK_TYPES)
               .includes(:employee)
               .map(&:employee)
    end

    def find_weekday_for_compensation(weekend_shift_day:, employee:, reverse: false, work_type:)
      candidate_days = compensation_candidate_days_for(weekend_shift_day, work_type)

      if work_type == "saturday_off"
        sunday_off_day = compensation_day_for(employee, weekend_shift_day, "sunday_off")

        if sunday_off_day.present?
          candidate_days = candidate_days.select do |day|
            day.target_date > sunday_off_day.target_date
          end
        end
      end

      available_days = candidate_days.select do |day|
        next false if employee_assignment_exists_on?(day, employee)
        next false if day.leave_request_for(employee).present?

        true
      end

      ordered_days =
        if reverse
          available_days.sort_by do |day|
            [existing_working_assignment_count(day), -day.target_date.jd]
          end
        else
          available_days.sort_by do |day|
            [existing_working_assignment_count(day), day.target_date.jd]
          end
        end

      ordered_days.first
    end

    def compensation_day_for(employee, weekend_shift_day, work_type)
      candidate_days = compensation_candidate_days_for(weekend_shift_day, work_type)

      candidate_days.find do |day|
        employee_assignment_exists_on?(day, employee, work_types: work_type)
      end
    end

    def compensation_candidate_days_for(weekend_shift_day, work_type)
      case work_type
      when "saturday_off"
        week_start = weekend_shift_day.target_date.beginning_of_week(:monday)
        week_end   = weekend_shift_day.target_date.end_of_week(:monday)

        shift_days.select do |day|
          day.target_date >= week_start &&
            day.target_date <= week_end &&
            !weekend_or_holiday?(day) &&
            !day.target_date.monday?
        end
      when "sunday_off"
        next_week_start = weekend_shift_day.target_date.next_week(:monday)
        next_week_end   = next_week_start.end_of_week(:monday)

        shift_days.select do |day|
          day.target_date >= next_week_start &&
            day.target_date <= next_week_end &&
            !weekend_or_holiday?(day) &&
            !day.target_date.monday?
        end
      when "national_holiday"
        week_start = weekend_shift_day.target_date.beginning_of_week(:monday)
        week_end   = weekend_shift_day.target_date.end_of_week(:monday)

        shift_days.select do |day|
          day.target_date >= week_start &&
            day.target_date <= week_end &&
            !weekend_or_holiday?(day)
        end
      else
        []
      end
    end

    def assign_rest_day(shift_day, employee, work_type)
      return if employee_assignment_exists_on?(shift_day, employee)

      assignment = shift_day.shift_assignments.create!(
        employee: employee,
        work_type: work_type
      )

      Rails.logger.debug "[compensation] created assignment_id=#{assignment.id} employee_id=#{employee.id} shift_day_id=#{shift_day.id} work_type=#{work_type}"
    end

    # -------------------------
    # 共通
    # -------------------------
    def candidate_employees_for(shift_day)
      candidates = employees.reject { |employee| unavailable_for_work_assignment?(shift_day, employee) }

      candidates.sort_by do |employee|
        [weekday_assignment_count(employee), employee.id]
      end
    end

    def must_staff_candidate_employees_for(shift_day)
      employees.select(&:must_staff)
               .reject { |employee| unavailable_for_work_assignment?(shift_day, employee) }
               .sort_by do |employee|
        [weekday_assignment_count(employee), employee.id]
      end
    end

    def must_staff_assigned_on?(shift_day)
      shift_day.shift_assignments.joins(:employee)
               .where(work_type: %w[day_shift middle_shift night_shift], employees: { must_staff: true })
               .exists?
    end

    def unavailable_for_work_assignment?(shift_day, employee)
      shift_day.leave_request_for(employee).present? || shift_day.assignment_for(employee).present?
    end

    def weekday_assignment_count(employee)
      weekday_assignment_counts[employee.id] || 0
    end

    def weekday_assignment_counts
      @weekday_assignment_counts ||= begin
        counts = ShiftAssignment.joins(:shift_day)
                                .where(shift_days: { shift_period_id: shift_period.id })
                                .where(work_type: %w[day_shift middle_shift])
                                .where.not(shift_days: { day_type: %w[saturday sunday holiday] })
                                .group(:employee_id)
                                .count

        Hash.new(0).merge(counts)
      end
    end

    def weekly_assignment_count(employee, shift_day)
      week_start = shift_day.target_date.beginning_of_week(:monday)
      week_end   = shift_day.target_date.end_of_week(:monday)

      ShiftAssignment.joins(:shift_day)
                     .where(employee: employee, shift_days: { shift_period_id: shift_period.id })
                     .where(shift_days: { target_date: week_start..week_end })
                     .where(work_type: %w[day_shift middle_shift saturday_off sunday_off national_holiday])
                     .count
    end

    def increment_weekday_assignment_count(employee)
      weekday_assignment_counts[employee.id] += 1
    end

    def employee_assignment_exists_on?(shift_day, employee, work_types: nil)
      scope = shift_day.shift_assignments.where(employee: employee)
      scope = scope.where(work_type: work_types) if work_types.present?
      scope.exists?
    end

    def selectable_zone_for(employee, zone_counts)
      return nil if employee.blank?

      assignable_zones = assignable_regular_zones_for(employee)
      return nil if assignable_zones.blank?

      assignable_zones.min_by do |zone|
        [
          zone_counts[zone.id].to_i.zero? ? 0 : 1,
          zone_counts[zone.id] || 0,
          primary_zone_priority(employee, zone),
          zone.position,
          zone.id
        ]
      end
    end

    def assignable_regular_zones_for(employee)
      employee.zones.where(active: true).where.not(name: "混合").order(:position, :id).to_a
    end

    def primary_zone_priority(employee, zone)
      employee.primary_zone_id == zone.id ? 0 : 1
    end

    def regular_zone_assignment_counts_for(shift_day)
      counts =
        shift_day.shift_assignments
                 .joins(:zone)
                 .where(work_type: "day_shift")
                 .where.not(zones: { name: "混合" })
                 .group(:zone_id)
                 .count

      Hash.new(0).merge(counts)
    end

    def existing_working_assignment_count(shift_day)
      shift_day.shift_assignments.where(work_type: %w[day_shift middle_shift]).count
    end

    def weekend_or_holiday_shift_days
      shift_days.select { |day| weekend_or_holiday?(day) }
    end

    def weekday_shift_days
      shift_days.reject { |day| weekend_or_holiday?(day) }
    end
  end
end
