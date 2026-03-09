defmodule BookVisually.Repo.Migrations.CreateAccountTransactions do
  use Ecto.Migration

  def change do
    create table(:account_transactions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :transaction_type, :string, null: false
      add :transaction_date, :utc_datetime, null: false
      add :amount, :decimal, precision: 15, scale: 2, null: false

      add :from_account_id, references(:financial_accounts, type: :uuid, on_delete: :nilify_all)
      add :to_account_id, references(:financial_accounts, type: :uuid, on_delete: :nilify_all)
      add :expense_id, references(:expenses, type: :uuid, on_delete: :nilify_all)

      add :reference_number, :string
      add :description, :text
      add :initiated_by_user_id, :integer, default: 1
      add :notes, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create constraint(:account_transactions, :valid_transaction_type,
      check: "transaction_type IN ('deposit', 'withdrawal', 'transfer', 'expense', 'income', 'adjustment')"
    )

    create constraint(:account_transactions, :positive_amount,
      check: "amount > 0"
    )

    create constraint(:account_transactions, :valid_deposit,
      check: "(transaction_type != 'deposit') OR (from_account_id IS NULL AND to_account_id IS NOT NULL)"
    )

    create constraint(:account_transactions, :valid_withdrawal,
      check: "(transaction_type != 'withdrawal') OR (from_account_id IS NOT NULL AND to_account_id IS NULL)"
    )

    create constraint(:account_transactions, :valid_transfer,
      check: "(transaction_type != 'transfer') OR (from_account_id IS NOT NULL AND to_account_id IS NOT NULL AND from_account_id != to_account_id)"
    )

    create constraint(:account_transactions, :valid_expense,
      check: "(transaction_type != 'expense') OR (from_account_id IS NOT NULL AND expense_id IS NOT NULL)"
    )

    create constraint(:account_transactions, :valid_income,
      check: "(transaction_type != 'income') OR (to_account_id IS NOT NULL)"
    )

    create index(:account_transactions, [:transaction_type])
    create index(:account_transactions, [:transaction_date])
    create index(:account_transactions, [:from_account_id])
    create index(:account_transactions, [:to_account_id])
    create index(:account_transactions, [:expense_id])
    create index(:account_transactions, [:from_account_id, :transaction_date])
    create index(:account_transactions, [:to_account_id, :transaction_date])
  end
end
