defmodule BookVisually.Repo.Migrations.CreateSupplyResourceProperties do
  use Ecto.Migration

  def change do
    create table(:supply_resource_properties, primary_key: false) do
      add :resource_id, references(:resources, type: :uuid, on_delete: :delete_all), primary_key: true

      # Alert settings
      add :issues_out_of_stock_alerts, :boolean, default: false
      add :out_of_stock_alert_quantity, :decimal, precision: 15, scale: 4

      # Current inventory (cached for performance)
      add :current_stock_quantity, :decimal, precision: 15, scale: 4, default: 0
      add :status, :string, default: "in_stock"

      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create constraint(:supply_resource_properties, :valid_status,
      check: "status IN ('in_stock', 'low_stock', 'out_of_stock')"
    )

    create constraint(:supply_resource_properties, :non_negative_stock,
      check: "current_stock_quantity >= 0"
    )
  end
end
