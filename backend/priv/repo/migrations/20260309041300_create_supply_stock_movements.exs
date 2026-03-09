defmodule BookVisually.Repo.Migrations.CreateSupplyStockMovements do
  use Ecto.Migration

  def change do
    create table(:supply_stock_movements, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :resource_id, references(:resources, type: :uuid, on_delete: :restrict), null: false
      add :expense_id, references(:expenses, type: :uuid, on_delete: :nilify_all)

      add :movement_type, :string, null: false
      add :movement_date, :utc_datetime, null: false

      # Quantity change (positive = increase, negative = decrease)
      add :quantity_change, :decimal, precision: 15, scale: 4, null: false
      add :unit_of_measure, :string

      # Stock level after this movement (cached for performance)
      add :stock_after_movement, :decimal, precision: 15, scale: 4, null: false

      # Who used it (for usage tracking)
      add :used_by, :string

      add :description, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create constraint(:supply_stock_movements, :valid_movement_type,
      check: "movement_type IN ('purchase', 'usage', 'adjustment', 'disposal', 'return')"
    )

    create constraint(:supply_stock_movements, :quantity_change_not_zero,
      check: "quantity_change != 0"
    )

    create constraint(:supply_stock_movements, :non_negative_stock_after,
      check: "stock_after_movement >= 0"
    )

    create index(:supply_stock_movements, [:resource_id])
    create index(:supply_stock_movements, [:expense_id])
    create index(:supply_stock_movements, [:movement_date])
    create index(:supply_stock_movements, [:movement_type])
    create index(:supply_stock_movements, [:resource_id, :movement_date])
  end
end
