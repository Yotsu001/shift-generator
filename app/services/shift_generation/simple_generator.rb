module ShiftGeneration
  class SimpleGenerator
    WEEKDAY_MAX_ASSIGNMENTS_COUNT = 5
    WEEKEND_AUTO_WORK_TYPES = %w[day_shift middle_shift].freeze

    def initialize(shift_period)
      @shift_period = shift_period
      @shift_days   = shift_period.shift_days.includes(:shift_assignments, :leave_requests).order(:target_date)
      @employees    = Employee.active_ordered
    end

    def call
      Rails.logger.debug "=== SimpleGenerator start shift_period_id=#{shift_period.id} ==="

      created_count = 0

      ActiveRecord::Base.transaction do
        weekend_or_holiday_shift_days.each do |shift_day|
          Rails.logger.debug "---- weekend/holiday shift_day_id=#{shift_day.id} date=#{shift_day.target_date} day_type=#{shift_day.day_type} ----"

          before_count = shift_day.shift_assignments.count
          assign_weekend_or_holiday(shift_day)
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
      assign_mixed_zone_for_day(shift_day)

      created_count = existing_working_assignment_count(shift_day)

      candidate_employees_for(shift_day).each do |employee|
        break if created_count >= weekday_max_assignments_count

        next if shift_day.leave_request_for(employee).present?
        next if shift_day.assignment_for(employee).present?

        zone = selectable_zone_for(employee)
        next if zone.blank?

        assignment = shift_day.shift_assignments.build(
          employee: employee,
          work_type: "day_shift",
          zone: zone
        )

        assignment.save!
        created_count += 1

        Rails.logger.debug "[weekday] created assignment_id=#{assignment.id} employee_id=#{employee.id} zone_name=#{zone.name} work_type=#{assignment.work_type}"
      end
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

      selected_employees = select_weekend_employees(available_employees).first(missing_work_types.size)

      missing_work_types.each_with_index do |work_type, index|
        employee = selected_employees[index]
        next if employee.blank?

        create_weekend_assignment(shift_day, employee, work_type)
      end
    end

    def weekend_candidate_employees_for(shift_day)
      employees.reject do |employee|
        shift_day.leave_request_for(employee).present? || shift_day.assignment_for(employee).present?
      end
    end

    def select_weekend_employees(available_employees)
      available_employees.sort_by { |employee| [weekend_assignment_count(employee), employee.id] }
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
    # 混合区割当
    # -------------------------
    def assign_mixed_zone_for_day(shift_day)
      mixed_zone = mixed_zone_record
      return if mixed_zone.blank?
      return if mixed_zone_already_assigned?(shift_day)
      return if existing_working_assignment_count(shift_day) >= weekday_max_assignments_count

      candidates = mixed_zone_candidate_employees_for(shift_day)
      employee = candidates.first
      return if employee.blank?

      assignment = shift_day.shift_assignments.build(
        employee: employee,
        work_type: "middle_shift",
        zone: mixed_zone
      )

      assignment.save!

      Rails.logger.debug "[mixed] created assignment_id=#{assignment.id} employee_id=#{employee.id} zone_name=#{mixed_zone.name} work_type=#{assignment.work_type}"
    end

    def mixed_zone_already_assigned?(shift_day)
      shift_day.shift_assignments.joins(:zone).exists?(zones: { name: "混合" })
    end

    def mixed_zone_candidate_employees_for(shift_day)
      candidates = employees.reject do |employee|
        shift_day.leave_request_for(employee).present? || shift_day.assignment_for(employee).present?
      end

      candidates.sort_by do |employee|
        [mixed_assignment_count(employee), employee.id]
      end
    end

    def mixed_assignment_count(employee)
      ShiftAssignment.joins(:zone, :shift_day)
                     .where(
                       employee: employee,
                       zones: { name: "混合" },
                       shift_days: { shift_period_id: shift_period.id }
                     )
                     .count
    end

    # -------------------------
    # 代償休
    # -------------------------
    def assign_weekend_compensatory_days!
      assign_compensatory_saturday_off_for_saturday_work! +
        assign_compensatory_sunday_off_for_sunday_work!
    end

    def assign_compensatory_saturday_off_for_saturday_work!
      created_count = 0

      saturday_shift_days.each do |shift_day|
        working_employees_on(shift_day).each do |employee|
          target_day = find_weekday_for_compensation(
            weekend_shift_day: shift_day,
            employee: employee,
            reverse: false
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
            reverse: true
          )

          next if target_day.blank?

          assign_rest_day(target_day, employee, "sunday_off")
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

    def working_employees_on(shift_day)
      shift_day.shift_assignments
               .where(work_type: WEEKEND_AUTO_WORK_TYPES)
               .includes(:employee)
               .map(&:employee)
    end

    def find_weekday_for_compensation(weekend_shift_day:, employee:, reverse: false)
      candidate_days = compensation_candidate_days_for(weekend_shift_day)
      candidate_days = candidate_days.reverse if reverse

      candidate_days.find do |day|
        next false if day.assignment_for(employee).present?
        next false if day.leave_request_for(employee).present?

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

    def assign_rest_day(shift_day, employee, work_type)
      shift_day.shift_assignments.create!(
        employee: employee,
        work_type: work_type
      )
    end

    # -------------------------
    # 共通
    # -------------------------
    def candidate_employees_for(shift_day)
      candidates = employees.reject do |employee|
        shift_day.leave_request_for(employee).present? || shift_day.assignment_for(employee).present?
      end

      candidates.sort_by do |employee|
        [weekday_assignment_count(employee), employee.id]
      end
    end

    def weekday_assignment_count(employee)
      ShiftAssignment.joins(:shift_day)
                    .where(employee: employee, shift_days: { shift_period_id: shift_period.id })
                    .where(work_type: %w[day_shift middle_shift])
                    .where.not(shift_days: { day_type: %w[saturday sunday holiday] })
                    .count
    end

    def selectable_zone_for(employee)
      return fallback_regular_zone if employee.blank?

      primary_zone = employee.primary_zone
      return primary_zone if primary_zone.present? && primary_zone.name != "混合"

      fallback_regular_zone
    end

    def fallback_regular_zone
      @fallback_regular_zone ||= Zone.where.not(name: "混合").order(:position).first
    end

    def existing_working_assignment_count(shift_day)
      shift_day.shift_assignments.where(work_type: %w[day_shift middle_shift]).count
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