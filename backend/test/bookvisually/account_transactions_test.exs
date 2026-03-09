defmodule BookVisually.AccountTransactionsTest do
  use BookVisually.DataCase

  alias BookVisually.Accounts
  alias BookVisually.Expenses

  describe "account_transactions" do
    setup do
      {:ok, bank_account} = Accounts.create_account(%{
        name: "Main Bank",
        account_type: "bank_account",
        bank_name: "First Bank"
      })

      {:ok, cash_account} = Accounts.create_account(%{
        name: "Cash at Hand",
        account_type: "cash_at_hand"
      })

      # Add initial balance to bank account
      {:ok, bank_account} = Accounts.increase_balance(bank_account, Decimal.new("1000"))

      %{bank_account: bank_account, cash_account: cash_account}
    end

    test "list_transactions/0 returns all transactions", %{bank_account: account} do
      {:ok, _transaction} = Accounts.create_deposit(%{
        to_account_id: account.id,
        amount: Decimal.new("100")
      })

      transactions = Accounts.list_transactions()
      assert length(transactions) == 1
    end

    test "list_transactions_by_account/1 filters by account", %{bank_account: bank, cash_account: cash} do
      {:ok, _t1} = Accounts.create_deposit(%{to_account_id: bank.id, amount: Decimal.new("100")})
      {:ok, _t2} = Accounts.create_deposit(%{to_account_id: cash.id, amount: Decimal.new("50")})

      bank_transactions = Accounts.list_transactions_by_account(bank.id)
      assert length(bank_transactions) == 1
    end

    test "list_transactions_by_date_range/2 filters by date", %{bank_account: account} do
      {:ok, _t1} = Accounts.create_deposit(%{
        to_account_id: account.id,
        amount: Decimal.new("100"),
        transaction_date: ~U[2026-03-01 10:00:00Z]
      })
      {:ok, _t2} = Accounts.create_deposit(%{
        to_account_id: account.id,
        amount: Decimal.new("50"),
        transaction_date: ~U[2026-03-15 10:00:00Z]
      })

      transactions = Accounts.list_transactions_by_date_range(~D[2026-03-10], ~D[2026-03-20])
      assert length(transactions) == 1
    end

    test "create_deposit/1 creates transaction and increases balance", %{bank_account: account} do
      initial_balance = account.current_balance

      assert {:ok, transaction} = Accounts.create_deposit(%{
        to_account_id: account.id,
        amount: Decimal.new("500"),
        description: "Investment deposit"
      })

      assert transaction.transaction_type == "deposit"
      assert Decimal.equal?(transaction.amount, Decimal.new("500"))
      assert transaction.to_account_id == account.id
      assert transaction.from_account_id == nil

      updated_account = Accounts.get_account!(account.id)
      expected_balance = Decimal.add(initial_balance, Decimal.new("500"))
      assert Decimal.equal?(updated_account.current_balance, expected_balance)
    end

    test "create_deposit/1 without to_account_id returns error" do
      assert {:error, changeset} = Accounts.create_deposit(%{
        amount: Decimal.new("100")
      })

      assert "is required for deposits" in errors_on(changeset).to_account_id
    end

    test "create_withdrawal/1 creates transaction and decreases balance", %{bank_account: account} do
      initial_balance = account.current_balance

      assert {:ok, transaction} = Accounts.create_withdrawal(%{
        from_account_id: account.id,
        amount: Decimal.new("200"),
        description: "Cash withdrawal"
      })

      assert transaction.transaction_type == "withdrawal"
      assert Decimal.equal?(transaction.amount, Decimal.new("200"))
      assert transaction.from_account_id == account.id
      assert transaction.to_account_id == nil

      updated_account = Accounts.get_account!(account.id)
      expected_balance = Decimal.sub(initial_balance, Decimal.new("200"))
      assert Decimal.equal?(updated_account.current_balance, expected_balance)
    end

    test "create_withdrawal/1 fails when insufficient balance", %{cash_account: account} do
      assert {:error, changeset} = Accounts.create_withdrawal(%{
        from_account_id: account.id,
        amount: Decimal.new("100")
      })

      assert "must be greater than or equal to 0" in errors_on(changeset).current_balance
    end

    test "create_transfer/1 creates transaction and updates both balances", %{bank_account: bank, cash_account: cash} do
      bank_initial = bank.current_balance
      cash_initial = cash.current_balance

      assert {:ok, transaction} = Accounts.create_transfer(%{
        from_account_id: bank.id,
        to_account_id: cash.id,
        amount: Decimal.new("300"),
        description: "Transfer to cash"
      })

      assert transaction.transaction_type == "transfer"
      assert Decimal.equal?(transaction.amount, Decimal.new("300"))
      assert transaction.from_account_id == bank.id
      assert transaction.to_account_id == cash.id

      updated_bank = Accounts.get_account!(bank.id)
      updated_cash = Accounts.get_account!(cash.id)

      assert Decimal.equal?(updated_bank.current_balance, Decimal.sub(bank_initial, Decimal.new("300")))
      assert Decimal.equal?(updated_cash.current_balance, Decimal.add(cash_initial, Decimal.new("300")))
    end

    test "create_transfer/1 without from_account_id returns error", %{cash_account: account} do
      assert {:error, changeset} = Accounts.create_transfer(%{
        to_account_id: account.id,
        amount: Decimal.new("100")
      })

      assert "is required for transfers" in errors_on(changeset).from_account_id
    end

    test "create_transfer/1 without to_account_id returns error", %{bank_account: account} do
      assert {:error, changeset} = Accounts.create_transfer(%{
        from_account_id: account.id,
        amount: Decimal.new("100")
      })

      assert "is required for transfers" in errors_on(changeset).to_account_id
    end

    test "create_transfer/1 with same from and to account returns error", %{bank_account: account} do
      assert {:error, changeset} = Accounts.create_transfer(%{
        from_account_id: account.id,
        to_account_id: account.id,
        amount: Decimal.new("100")
      })

      assert "cannot be the same as from_account" in errors_on(changeset).to_account_id
    end

    test "create_expense_payment/1 creates transaction and decreases balance", %{bank_account: account} do
      # Create a resource and expense first
      {:ok, resource} = BookVisually.Resources.create_resource(%{
        name: "Office Supplies",
        resource_category: "supply"
      })

      {:ok, expense} = Expenses.create_expense(%{
        resource_id: resource.id,
        expense_date: ~D[2026-03-08],
        total_amount: Decimal.new("150")
      })

      initial_balance = account.current_balance

      assert {:ok, transaction} = Accounts.create_expense_payment(%{
        from_account_id: account.id,
        expense_id: expense.id,
        amount: Decimal.new("150"),
        description: "Payment for office supplies"
      })

      assert transaction.transaction_type == "expense"
      assert Decimal.equal?(transaction.amount, Decimal.new("150"))
      assert transaction.from_account_id == account.id
      assert transaction.expense_id == expense.id

      updated_account = Accounts.get_account!(account.id)
      expected_balance = Decimal.sub(initial_balance, Decimal.new("150"))
      assert Decimal.equal?(updated_account.current_balance, expected_balance)
    end

    test "create_expense_payment/1 without expense_id returns error", %{bank_account: account} do
      assert {:error, changeset} = Accounts.create_expense_payment(%{
        from_account_id: account.id,
        amount: Decimal.new("100")
      })

      assert "is required for expense payments" in errors_on(changeset).expense_id
    end

    test "create_income/1 creates transaction and increases balance", %{bank_account: account} do
      initial_balance = account.current_balance

      assert {:ok, transaction} = Accounts.create_income(%{
        to_account_id: account.id,
        amount: Decimal.new("2000"),
        description: "Customer payment"
      })

      assert transaction.transaction_type == "income"
      assert Decimal.equal?(transaction.amount, Decimal.new("2000"))
      assert transaction.to_account_id == account.id

      updated_account = Accounts.get_account!(account.id)
      expected_balance = Decimal.add(initial_balance, Decimal.new("2000"))
      assert Decimal.equal?(updated_account.current_balance, expected_balance)
    end

    test "transactions automatically set transaction_date if not provided", %{bank_account: account} do
      {:ok, transaction} = Accounts.create_deposit(%{
        to_account_id: account.id,
        amount: Decimal.new("100")
      })

      assert transaction.transaction_date != nil
    end

    test "transactions with negative amount return error", %{bank_account: account} do
      assert {:error, changeset} = Accounts.create_deposit(%{
        to_account_id: account.id,
        amount: Decimal.new("-100")
      })

      assert "must be greater than 0" in errors_on(changeset).amount
    end

    test "transactions rollback on balance update failure", %{cash_account: account} do
      # Try to withdraw more than available (should fail)
      result = Accounts.create_withdrawal(%{
        from_account_id: account.id,
        amount: Decimal.new("1000")
      })

      assert {:error, _changeset} = result

      # Verify no transaction was created
      transactions = Accounts.list_transactions_by_account(account.id)
      assert transactions == []

      # Verify balance unchanged
      updated_account = Accounts.get_account!(account.id)
      assert Decimal.equal?(updated_account.current_balance, Decimal.new("0"))
    end
  end
end
