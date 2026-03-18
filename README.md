# テーブル設計

## users テーブル

| Column             | Type   | Options     |
| ------------------ | ------ | ----------- |
| name               | string | null: false |
| email              | string | null: false, unique: true |
| encrypted_password | string | null: false |

## employees テーブル

| Column            | Type    | Options     |
| ----------------- | ------- | ----------- |
| name              | string  | null: false |
| code              | integer | unique: true |
| active            | boolean | null: false |
| position          | integer | null: false |
| can_work_saturday | boolean | null: false |
| can_work_sunday   | boolean | null: false |
| can_day_shift     | boolean | null: false |
| can_night_shift   | boolean | null: false |
| can_mixed_zone    | boolean | null: false |
| notes             | text    |             |

### Indexes
- unique index on `:code`

#### Association
- has_many :assignments
- has_many :leave_requests
- has_many :employee_zone_preferences
- has_many :preferred_zones, through: :employee_zone_preferences, source: :zone

## zones テーブル

| Column   | Type    | Options     |
| -------- | ------- | ----------- |
| name     | string  | null: false |
| code     | string  | null: false |
| category | integer | null: false |
| position | integer | null: false |
| active   | boolean | null: false |

### Indexes
- unique index on `:code`

#### Association
- has_many :assignments
- has_many :employee_zone_preferences

## shift_periods テーブル

| Column        | Type       | Options     |
| ------------- | ---------- | ----------- |
| name          | string     | null: false |
| start_date    | date       | null: false |
| end_date      | date       | null: false |
| status        | integer    | null: false |
| created_by_id | references | foreign_key: true |

### Indexes
- index on `[:start_date, :end_date]`

#### Association
- belongs_to :created_by, class_name: "User"
- has_many :shift_days

## shift_days テーブル

| Column          | Type       | Options     |
| --------------- | ---------- | ----------- |
| shift_period_id | references | null: false, foreign_key: true |
| target_date     | date       | null: false |
| weekday         | integer    | null: false |
| holiday_type    | integer    | null: false |

### Indexes
- unique index on `[:shift_period_id, :target_date]`

#### Association
- belongs_to :shift_period
- has_many :assignments

## assignments テーブル

| Column        | Type       | Options     |
| ------------- | ---------- | ----------- |
| shift_day_id  | references | null: false, foreign_key: true |
| employee_id   | references | null: false, foreign_key: true |
| zone_id       | references | foreign_key: true |
| work_type     | integer    | null: false |
| auto_assigned | boolean    | null: false |
| locked        | boolean    | null: false |
| notes         | text       |             |

### Indexes
- unique index on `[:shift_day_id, :employee_id]`

#### Association
- belongs_to :shift_day
- belongs_to :employee
- belongs_to :zone

## leave_requests テーブル

| Column       | Type       | Options     |
| ------------ | ---------- | ----------- |
| employee_id  | references | null: false, foreign_key: true |
| request_date | date       | null: false |
| request_type | integer    | null: false |
| status       | integer    | null: false |
| notes        | text       |             |

### Indexes
- unique index on `[:employee_id, request_date]`

#### Association
- belongs_to :employee

## employee_zone_preferences テーブル

| Column           | Type       | Options     |
| ---------------- | ---------- | ----------- |
| employee_id      | references | null: false, foreign_key: true |
| zone_id          | references | null: false, foreign_key: true |
| preference_level | integer    | null: false |
| fixed_ratio      | integer    |             |

### Indexes
- unique index on `[:employee_id, zone_id]`

#### Association
- belongs_to :employee
- belongs_to :zone
