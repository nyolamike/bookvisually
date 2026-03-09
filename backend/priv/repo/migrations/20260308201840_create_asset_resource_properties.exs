defmodule BookVisually.Repo.Migrations.CreateAssetResourceProperties do
  use Ecto.Migration

  def change do
    create table(:asset_resource_properties, primary_key: false) do
      add :resource_id, references(:resources, type: :uuid, on_delete: :delete_all), primary_key: true

      # Purchase info
      add :purchase_date, :date, null: false
      add :purchase_cost, :decimal, precision: 15, scale: 2, null: false

      # Depreciation
      add :depreciation_method, :string
      add :depreciation_rate, :decimal, precision: 5, scale: 2
      add :current_value, :decimal, precision: 15, scale: 2

      # Warranty
      add :has_warranty, :boolean, default: false
      add :warranty_expiry_date, :date
      add :warranty_status, :string, default: "na"

      # Guarantee
      add :has_guarantee, :boolean, default: false
      add :guarantee_expiry_date, :date
      add :guarantee_status, :string, default: "na"

      # Asset status
      add :status, :string, default: "okay"

      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create constraint(:asset_resource_properties, :valid_depreciation_method,
      check: "depreciation_method IN ('straight_line', 'declining_balance', 'none') OR depreciation_method IS NULL"
    )

    create constraint(:asset_resource_properties, :valid_warranty_status,
      check: "warranty_status IN ('na', 'active', 'used', 'expired')"
    )

    create constraint(:asset_resource_properties, :valid_guarantee_status,
      check: "guarantee_status IN ('na', 'active', 'used', 'expired')"
    )

    create constraint(:asset_resource_properties, :valid_status,
      check: "status IN ('okay', 'in_use', 'offsite', 'damaged', 'destroyed', 'disposed')"
    )

    create constraint(:asset_resource_properties, :positive_purchase_cost,
      check: "purchase_cost > 0"
    )

    create constraint(:asset_resource_properties, :non_negative_current_value,
      check: "current_value >= 0 OR current_value IS NULL"
    )
  end
end
