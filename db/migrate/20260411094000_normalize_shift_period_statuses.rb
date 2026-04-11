class NormalizeShiftPeriodStatuses < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      UPDATE shift_periods
      SET status = CASE status
                   WHEN 1 THEN 0
                   WHEN 2 THEN 1
                   ELSE status
                   END
    SQL
  end

  def down
    execute <<~SQL
      UPDATE shift_periods
      SET status = CASE status
                   WHEN 1 THEN 2
                   ELSE status
                   END
    SQL
  end
end
