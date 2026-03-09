defmodule BookVisually.Repo.Migrations.CreateUtilityBills do
  use Ecto.Migration

  def change do
    create table(:utility_bills, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :resource_id, references(:resources, type: :uuid, on_delete: :nilify_all)

      add :bill_date, :date, null: false
      add :due_date, :date

      # Meter/reading fields
      add :bill_reading, :decimal, precision: 15, scale: 4
      add :previous_reading, :decimal, precision: 15, scale: 4
      add :quantity_consumed, :decimal, precision: 15, scale: 4
      add :unit_of_measure, :string

      add :unit_cost, :decimal, precision: 15, scale: 2
      add :total_amount, :decimal, precision: 15, scale: 2, null: false

      add :vendor, :string
      add :reference_number, :string
      add :status, :string, default: "unpaid"
      add :notes, :text

      add :is_deleted, :boolean, default: false
      add :deleted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create constraint(:utility_bills, :valid_status,
      check: "status IN ('unpaid', 'partially_paid', 'paid', 'overdue', 'cancelled')"
    )

    create constraint(:utility_bills, :non_negative_total,
      check: "total_amount >= 0"
    )

    create constraint(:utility_bills, :valid_due_date,
      check: "due_date IS NULL OR due_date >= bill_date"
    )

    create index(:utility_bills, [:resource_id])
    create index(:utility_bills, [:status])
    create index(:utility_bills, [:due_date])
    create index(:utility_bills, [:bill_date])
    create index(:utility_bills, [:is_deleted])
    create index(:utility_bills, [:status, :due_date], where: "is_deleted = false")
  end
end
