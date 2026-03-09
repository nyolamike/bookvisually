defmodule BookVisually.Repo.Migrations.CreateFinancialAccounts do
  use Ecto.Migration

  def change do
    create table(:financial_accounts, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :account_type, :string, null: false

      # Current balance (cached for performance)
      add :current_balance, :decimal, precision: 15, scale: 2, default: 0

      # Totals (cached for performance)
      add :total_cash_in, :decimal, precision: 15, scale: 2, default: 0
      add :total_cash_out, :decimal, precision: 15, scale: 2, default: 0

      # Bank account specific fields
      add :bank_name, :string
      add :account_number, :string

      # Status
      add :status, :string, default: "active"

      add :notes, :text
      add :is_deleted, :boolean, default: false
      add :deleted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create constraint(:financial_accounts, :valid_account_type,
      check: "account_type IN ('cash_at_hand', 'bank_account', 'funding_line')"
    )

    create constraint(:financial_accounts, :valid_status,
      check: "status IN ('active', 'closed', 'frozen')"
    )

    create constraint(:financial_accounts, :non_negative_balance,
      check: "current_balance >= 0"
    )

    create index(:financial_accounts, [:account_type])
    create index(:financial_accounts, [:status])
    create index(:financial_accounts, [:is_deleted])
    create index(:financial_accounts, [:account_type, :status], where: "is_deleted = false")
  end
end
