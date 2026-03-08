defmodule BookVisually.Repo.Migrations.CreateResources do
  use Ecto.Migration

  def change do
    create table(:resources, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :description, :text
      add :resource_category, :string, null: false
      add :default_unit_of_measure, :string
      add :default_unit_cost, :decimal, precision: 15, scale: 2

      # Inspection tracking
      add :needs_periodic_inspection, :boolean, default: false
      add :inspection_interval_days, :integer
      add :last_inspection_date, :date
      add :next_inspection_date, :date
      add :days_to_inspection_alert, :integer

      add :notes, :text
      add :is_deleted, :boolean, default: false
      add :deleted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:resources, [:resource_category])
    create index(:resources, [:is_deleted])
    create index(:resources, [:resource_category], where: "is_deleted = false", name: :idx_resources_active)

    create constraint(:resources, :valid_resource_category,
      check: "resource_category IN ('subscription', 'utility', 'supply', 'asset')"
    )

    create constraint(:resources, :inspection_interval_required,
      check: "needs_periodic_inspection = false OR (needs_periodic_inspection = true AND inspection_interval_days IS NOT NULL)"
    )
  end
end
