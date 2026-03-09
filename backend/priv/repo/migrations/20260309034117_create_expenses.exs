defmodule BookVisually.Repo.Migrations.CreateExpenses do
  use Ecto.Migration

  def change do
    create table(:expenses, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :resource_id, references(:resources, type: :uuid, on_delete: :restrict), null: false
      add :paid_from_account_id, references(:financial_accounts, type: :uuid, on_delete: :nilify_all)

      add :expense_date, :date, null: false
      add :unit_cost, :decimal, precision: 15, scale: 2
      add :quantity, :decimal, precision: 15, scale: 4
      add :unit_of_measure, :string
      add :total_amount, :decimal, precision: 15, scale: 2, null: false
      add :description, :text

      # Metadata
      add :payment_method, :string
      add :reference_number, :string
      add :notes, :text

      add :is_deleted, :boolean, default: false
      add :deleted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create constraint(:expenses, :non_negative_total,
      check: "total_amount >= 0"
    )

    create index(:expenses, [:resource_id])
    create index(:expenses, [:expense_date])
    create index(:expenses, [:is_deleted])
    create index(:expenses, [:resource_id, :expense_date], where: "is_deleted = false")
    create index(:expenses, [:paid_from_account_id])
  end
end
