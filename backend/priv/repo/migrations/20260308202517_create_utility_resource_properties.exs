defmodule BookVisually.Repo.Migrations.CreateUtilityResourceProperties do
  use Ecto.Migration

  def change do
    create table(:utility_resource_properties, primary_key: false) do
      add :resource_id, references(:resources, type: :uuid, on_delete: :delete_all), primary_key: true

      add :bill_type, :string, null: false
      add :billing_cycle_days, :integer

      # Alert settings
      add :issues_bill_due_alerts, :boolean, default: false
      add :days_to_due_date_alert, :integer

      # Current bill status (cached for performance)
      add :current_bill_status, :string, default: "paid"
      add :last_bill_date, :date
      add :next_bill_due_date, :date
      add :current_bill_quantity_consumed, :decimal, precision: 15, scale: 4

      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create constraint(:utility_resource_properties, :valid_bill_type,
      check: "bill_type IN ('utility', 'service', 'salary', 'rent', 'other')"
    )

    create constraint(:utility_resource_properties, :valid_bill_status,
      check: "current_bill_status IN ('paid', 'unpaid', 'partially_paid', 'overdue')"
    )
  end
end
