# テーブル設計

現在のテーブル設計は `db/schema.rb` を基準にしています。

## users テーブル

| Column               | Type     | Options                          |
| -------------------- | -------- | -------------------------------- |
| email                | string   | null: false, default: ""         |
| encrypted_password   | string   | null: false, default: ""         |
| reset_password_token | string   | unique                           |
| reset_password_sent_at | datetime |                                  |
| remember_created_at  | datetime |                                  |
| name                 | string   | null: false, default: ""         |
| admin                | boolean  | null: false, default: false      |
| created_at           | datetime | null: false                      |
| updated_at           | datetime | null: false                      |

### Indexes
- unique index on `:email`
- unique index on `:reset_password_token`

### Association
- has_many :shift_periods
- has_many :shift_days, through: :shift_periods
- has_many :shift_assignments, through: :shift_days
- has_many :leave_requests, through: :shift_days
- has_many :employees

## employees テーブル

| Column               | Type       | Options                           |
| -------------------- | ---------- | --------------------------------- |
| name                 | string     | null: false                       |
| active               | boolean    | null: false, default: true        |
| display_order        | integer    | null: false, default: 0           |
| mixed_zone_enabled   | boolean    | null: false, default: false       |
| weekend_work_enabled | boolean    | null: false, default: true        |
| user_id              | references | null: false, foreign_key: true    |
| mixed_zone_preferred | boolean    | null: false, default: false       |
| primary_zone_id      | references | foreign_key: { to_table: :zones } |
| must_staff           | boolean    | null: false, default: false       |
| created_at           | datetime   | null: false                       |
| updated_at           | datetime   | null: false                       |

### Indexes
- index on `:active`
- index on `:display_order`
- index on `:must_staff`
- index on `:primary_zone_id`
- index on `:user_id`

### Association
- belongs_to :user
- belongs_to :primary_zone, class_name: "Zone", optional: true
- has_many :employee_zones
- has_many :zones, through: :employee_zones
- has_many :shift_assignments
- has_many :leave_requests

## zones テーブル

| Column     | Type     | Options                    |
| ---------- | -------- | -------------------------- |
| name       | string   | null: false, unique        |
| position   | integer  | null: false, default: 0    |
| active     | boolean  | null: false, default: true |
| created_at | datetime | null: false                |
| updated_at | datetime | null: false                |

### Indexes
- unique index on `:name`
- index on `:position`

### Association
- has_many :shift_assignments
- has_many :employee_zones
- has_many :employees, through: :employee_zones

## shift_periods テーブル

| Column     | Type       | Options                        |
| ---------- | ---------- | ------------------------------ |
| name       | string     | null: false                    |
| start_date | date       | null: false                    |
| end_date   | date       | null: false                    |
| status     | integer    | null: false, default: 0        |
| user_id    | references | null: false, foreign_key: true |
| created_at | datetime   | null: false                    |
| updated_at | datetime   | null: false                    |

### Indexes
- unique index on `[:user_id, :start_date, :end_date]`
- index on `:user_id`

### Association
- belongs_to :user
- has_many :shift_days
- has_many :shift_assignments, through: :shift_days
- has_many :leave_requests, through: :shift_days

## shift_days テーブル

| Column          | Type       | Options                        |
| --------------- | ---------- | ------------------------------ |
| shift_period_id | references | null: false, foreign_key: true |
| target_date     | date       | null: false                    |
| day_type        | integer    | null: false, default: 0        |
| created_at      | datetime   | null: false                    |
| updated_at      | datetime   | null: false                    |

### Indexes
- unique index on `[:shift_period_id, :target_date]`
- index on `:shift_period_id`

### Association
- belongs_to :shift_period
- has_many :shift_assignments
- has_many :leave_requests

## shift_assignments テーブル

| Column       | Type       | Options                     |
| ------------ | ---------- | --------------------------- |
| shift_day_id | references | null: false, foreign_key: true |
| user_id      | references | foreign_key: true           |
| work_type    | integer    | null: false, default: 0     |
| zone_id      | references | foreign_key: true           |
| employee_id  | references | foreign_key: true           |
| created_at   | datetime   | null: false                 |
| updated_at   | datetime   | null: false                 |

### Indexes
- unique index on `[:shift_day_id, :user_id]`
- index on `:employee_id`
- index on `:shift_day_id`
- index on `:user_id`
- index on `:zone_id`

### Association
- belongs_to :shift_day
- belongs_to :employee
- belongs_to :zone, optional: true

## leave_requests テーブル

| Column       | Type       | Options                     |
| ------------ | ---------- | --------------------------- |
| user_id      | references | foreign_key: true           |
| shift_day_id | references | null: false, foreign_key: true |
| note         | string     |                             |
| employee_id  | references | foreign_key: true           |
| created_at   | datetime   | null: false                 |
| updated_at   | datetime   | null: false                 |

### Indexes
- unique index on `[:user_id, :shift_day_id]`
- index on `:employee_id`
- index on `:shift_day_id`
- index on `:user_id`

### Association
- belongs_to :shift_day
- belongs_to :employee

## employee_zones テーブル

| Column      | Type       | Options                        |
| ----------- | ---------- | ------------------------------ |
| employee_id | references | null: false, foreign_key: true |
| zone_id     | references | null: false, foreign_key: true |
| created_at  | datetime   | null: false                    |
| updated_at  | datetime   | null: false                    |

### Indexes
- unique index on `[:employee_id, :zone_id]`
- index on `:employee_id`
- index on `:zone_id`

### Association
- belongs_to :employee
- belongs_to :zone
