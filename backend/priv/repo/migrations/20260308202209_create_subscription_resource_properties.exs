defmodule BookVisually.Repo.Migrations.CreateSubscriptionResourceProperties do
  use Ecto.Migration

  def change do
    create table(:subscription_resource_properties, primary_key: false) do
      add :resource_id, references(:resources, type: :uuid, on_delete: :delete_all), primary_key: true

      add :renewal_period, :string
      add :vendor, :string, null: false
      add :package, :string, null: false

      # Alert settings
      add :issues_expiry_alerts, :boolean, default: false
      add :days_left_to_alert, :integer

      # Current subscription (cached for performance)
      add :current_subscription_start_date, :date
      add :current_subscription_end_date, :date

      # Status
      add :status, :string, default: "active"

      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create constraint(:subscription_resource_properties, :valid_status,
      check: "status IN ('active', 'expired', 'cancelled')"
    )
  end
end
