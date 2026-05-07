# アプリケーション名
Shift Generator

## アプリケーション概要

Shift Generatorは、スタッフ・担当区・希望休を管理しながら、対象期間のシフト表を作成できるシフト管理アプリケーションです。

主な機能は以下のとおりです。

- ユーザー登録・ログイン
- スタッフの登録、編集、削除
- 担当区の登録、並び順変更、有効・無効管理
- スタッフごとの担当可能区、メイン担当区、マスト要員、土日勤務可否、混合区（中勤）優先の設定
- シフト期間の作成、編集、削除、確定
- シフト表上での勤務割当、希望休登録、編集、削除
- 平日・土曜・日曜・祝日を判定したシフト日の自動作成
- 希望休や担当可能区を考慮したシフト自動生成
- 土日祝勤務者への代休割当
- マスト要員が未割当の日付を通知するアラート

## URL

デプロイ完了後に記載予定です。

## テスト用アカウント

デプロイ完了後に記載予定です。

Basic認証を利用する場合は、以下の環境変数に設定した値を使用します。

- Basic認証ID: `BASIC_AUTH_USER`
- Basic認証Pass: `BASIC_AUTH_PASSWORD`

## 利用方法

1. Basic認証を設定している場合は、Basic認証のIDとパスワードを入力します。
2. 新規登録画面からユーザー名、メールアドレス、パスワードを登録します。
3. ログイン後、区一覧画面で勤務場所や担当区を登録します。
4. スタッフ一覧画面でスタッフを登録し、担当可能区、メイン担当区、マスト要員、土日勤務可否、中勤優先などを設定します。
5. シフト期間一覧画面から、シフトを作成したい期間を登録します。
6. シフト期間詳細画面の表から、スタッフごとの勤務や希望休を登録します。
7. 自動生成ボタンを押すと、希望休・担当可能区・土日勤務可否・マスト要員などを考慮して勤務が自動割当されます。
8. 必要に応じて手動で割当を修正し、シフト期間を確定します。

## アプリケーションを作成した背景

少人数の職場やチームでは、担当できる区、土日祝の勤務可否、希望休、必ず配置したいスタッフなど、複数の条件を見ながらシフトを作成する必要があります。手作業での調整は時間がかかり、入力漏れや配置ミスも起こりやすくなります。

このアプリケーションは、シフト作成者がスタッフ情報と希望休を一元管理し、条件を考慮した自動生成によってシフト作成の負担を減らすことを目的に作成しました。

## 実装した機能についての画像やGIFおよびその説明

画像・GIFはGyazoまたはGyazoGIFで撮影後、リンクを差し替えてください。

### トップページ・ログイン機能

[![Image from Gyazo](https://gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.png)](https://gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)

Deviseを利用してユーザー登録・ログイン機能を実装しています。ログイン後は登録スタッフ数や主要な操作への導線を確認できます。

### スタッフ管理機能

[![Image from Gyazo](https://gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.png)](https://gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)

スタッフ名、担当可能区、メイン担当区、マスト要員、土日勤務可否、中勤優先などを登録できます。スタッフごとの条件をシフト自動生成に反映します。

### 区管理機能

[![Image from Gyazo](https://gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.png)](https://gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)

勤務区を登録し、表示順や有効状態を管理できます。スタッフの担当可能区や勤務割当の選択肢として利用します。

### シフト期間管理機能

[![Image from Gyazo](https://gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.png)](https://gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)

シフト名、開始日、終了日を登録すると、対象期間の日付データが自動作成されます。土曜・日曜・祝日は自動判定されます。

### シフト表編集機能

[![Image from Gyazo](https://gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.png)](https://gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)

シフト表の各セルから勤務割当や希望休を登録できます。確定済みのシフト期間では編集・登録・削除ができないように制御しています。

### シフト自動生成機能

[![GIF from Gyazo](https://i.gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.gif)](https://gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)

希望休、担当可能区、土日勤務可否、中勤優先、マスト要員などを考慮して勤務を自動生成します。土日祝勤務者には代休も自動で割り当てます。

### マスト要員アラート機能

[![Image from Gyazo](https://gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.png)](https://gyazo.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)

平日にマスト要員が未割当の場合、該当日を一覧表示します。希望休や手動変更により必須配置が外れた場合でも、作成者が気づけるようにしています。

## 実装予定の機能

- シフト表のCSV出力機能
- スタッフごとの月間勤務回数や土日勤務回数の集計表示
- 希望休の申請者向け入力画面
- 祝日・土日祝の必要人数を画面から設定できる機能
- 自動生成条件の詳細設定
- スマートフォンでのシフト表閲覧性の向上

## データベース設計

ER図は以下のファイルに作成しています。

[ER図.dio](./ER図.dio)

```mermaid
erDiagram
  users ||--o{ employees : has_many
  users ||--o{ shift_periods : has_many
  employees ||--o{ employee_zones : has_many
  zones ||--o{ employee_zones : has_many
  employees ||--o{ shift_assignments : has_many
  employees ||--o{ leave_requests : has_many
  employees }o--|| zones : primary_zone
  shift_periods ||--o{ shift_days : has_many
  shift_days ||--o{ shift_assignments : has_many
  shift_days ||--o{ leave_requests : has_many
  zones ||--o{ shift_assignments : has_many

  users {
    bigint id PK
    string name
    string email
    string encrypted_password
    boolean admin
  }

  employees {
    bigint id PK
    string name
    boolean active
    integer display_order
    boolean mixed_zone_enabled
    boolean mixed_zone_preferred
    boolean weekend_work_enabled
    boolean must_staff
    bigint user_id FK
    bigint primary_zone_id FK
  }

  zones {
    bigint id PK
    string name
    integer position
    boolean active
  }

  employee_zones {
    bigint id PK
    bigint employee_id FK
    bigint zone_id FK
  }

  shift_periods {
    bigint id PK
    string name
    date start_date
    date end_date
    integer status
    bigint user_id FK
  }

  shift_days {
    bigint id PK
    date target_date
    integer day_type
    bigint shift_period_id FK
  }

  shift_assignments {
    bigint id PK
    integer work_type
    bigint shift_day_id FK
    bigint employee_id FK
    bigint zone_id FK
  }

  leave_requests {
    bigint id PK
    string note
    bigint shift_day_id FK
    bigint employee_id FK
  }
```

## 画面遷移図

画面遷移図は以下のファイルに作成しています。

[画面遷移図.dio](./画面遷移図.dio)

```mermaid
flowchart TD
  A["トップページ"] --> B["新規登録"]
  A --> C["ログイン"]
  B --> D["マイページ"]
  C --> D
  D --> E["シフト期間一覧"]
  D --> F["スタッフ一覧"]
  D --> G["区一覧"]
  D --> H["プロフィール編集"]
  E --> I["シフト期間新規作成"]
  E --> J["シフト期間詳細"]
  J --> K["シフト期間編集"]
  J --> L["勤務割当 登録・編集・削除"]
  J --> M["希望休 登録・編集・削除"]
  J --> N["シフト自動生成"]
  J --> O["割当リセット"]
  F --> P["スタッフ新規登録"]
  F --> Q["スタッフ詳細"]
  Q --> R["スタッフ編集"]
  G --> S["区新規登録"]
  G --> T["区編集"]
```

## 開発環境

- Ruby 3.2.0
- Ruby on Rails 7.1
- MySQL
- PostgreSQL
- Puma
- Devise
- importmap-rails
- Turbo Rails
- Stimulus Rails
- HolidayJp
- RSpec
- FactoryBot
- Faker
- RuboCop
- Capybara
- Selenium WebDriver

## ローカルでの動作方法

以下のコマンドを順に実行してください。

```bash
git clone リポジトリURL
cd shift-generator
bundle install
rails db:create
rails db:migrate
BASIC_AUTH_USER=admin BASIC_AUTH_PASSWORD=password rails s
```

ブラウザで以下にアクセスします。

```text
http://localhost:3000
```

テストを実行する場合は以下のコマンドを使用します。

```bash
bundle exec rspec
```

## 工夫したポイント

- スタッフをユーザーに紐づけ、ログインユーザーごとに自分のシフト期間・スタッフ情報を管理できるようにしました。
- シフト期間を作成すると、開始日から終了日までのシフト日を自動生成し、土曜・日曜・祝日を判定できるようにしました。
- 勤務割当と希望休が同じ日に重複しないよう、モデル側のバリデーションで整合性を保っています。
- 担当可能区以外の区にスタッフを割り当てられないようにし、シフト作成時の入力ミスを防いでいます。
- 土日祝勤務可否や中勤優先、マスト要員など、現場の調整で必要になりやすい条件をスタッフ情報として管理できるようにしました。
- シフト自動生成時には、希望休や既存割当を尊重しながら、勤務回数の偏りを抑えるようにしています。
- シフト確定後は編集・登録・削除を制限し、確定後の誤操作を防止しています。

## 改善点

- 現在の自動生成ロジックはシンプルなルールベースのため、勤務回数や連勤、曜日ごとの必要人数などをより細かく設定できるように改善したいです。
- 画面上でシフト全体のバランスを確認できるよう、スタッフ別・勤務種別別の集計表示を追加したいです。
- シフト表を外部共有しやすくするため、CSVやPDFでの出力機能を追加したいです。
- 希望休をスタッフ本人が入力できる画面を用意し、管理者の入力負担をさらに減らしたいです。
- スマートフォン表示では横長のシフト表が扱いづらくなるため、日付別表示やスタッフ別表示への切り替えを検討したいです。

## 制作時間

約80時間
