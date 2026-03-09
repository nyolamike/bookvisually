defmodule BookVisually.AccountsTest do
  use BookVisually.DataCase

  alias BookVisually.Accounts

  describe "financial_accounts" do
    @valid_attrs %{
      name: "Main Bank Account",
      description: "Primary business account",
      account_type: "bank_account",
      bank_name: "First National Bank",
      account_number: "1234567890",
      status: "active"
    }

    @cash_attrs %{
      name: "Cash at Reception",
      account_type: "cash_at_hand",
      status: "active"
    }

    @invalid_attrs %{name: nil, account_type: nil}

    test "list_accounts/0 returns all active accounts" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      accounts = Accounts.list_accounts()
      assert length(accounts) == 1
      assert hd(accounts).id == account.id
    end

    test "list_accounts/0 does not return deleted accounts" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      {:ok, _deleted} = Accounts.soft_delete_account(account)
      accounts = Accounts.list_accounts()
      assert accounts == []
    end

    test "list_accounts_by_type/1 filters by account type" do
      {:ok, _bank} = Accounts.create_account(@valid_attrs)
      {:ok, _cash} = Accounts.create_account(@cash_attrs)

      bank_accounts = Accounts.list_accounts_by_type("bank_account")
      cash_accounts = Accounts.list_accounts_by_type("cash_at_hand")

      assert length(bank_accounts) == 1
      assert length(cash_accounts) == 1
      assert hd(bank_accounts).account_type == "bank_account"
      assert hd(cash_accounts).account_type == "cash_at_hand"
    end

    test "list_accounts_by_status/1 filters by status" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      {:ok, _closed} = Accounts.update_account(account, %{status: "closed"})

      active_accounts = Accounts.list_accounts_by_status("active")
      closed_accounts = Accounts.list_accounts_by_status("closed")

      assert length(active_accounts) == 0
      assert length(closed_accounts) == 1
    end

    test "get_account!/1 returns the account with given id" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      fetched = Accounts.get_account!(account.id)
      assert fetched.id == account.id
      assert fetched.name == account.name
    end

    test "get_account!/1 raises when account is deleted" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      {:ok, _deleted} = Accounts.soft_delete_account(account)

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_account!(account.id)
      end
    end

    test "get_account_with_deleted!/1 returns deleted accounts" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      {:ok, _deleted} = Accounts.soft_delete_account(account)

      fetched = Accounts.get_account_with_deleted!(account.id)
      assert fetched.id == account.id
      assert fetched.is_deleted == true
    end

    test "create_account/1 with valid data creates an account" do
      assert {:ok, account} = Accounts.create_account(@valid_attrs)
      assert account.name == "Main Bank Account"
      assert account.account_type == "bank_account"
      assert account.bank_name == "First National Bank"
      assert account.account_number == "1234567890"
      assert account.status == "active"
      assert Decimal.equal?(account.current_balance, Decimal.new("0"))
      assert Decimal.equal?(account.total_cash_in, Decimal.new("0"))
      assert Decimal.equal?(account.total_cash_out, Decimal.new("0"))
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_account(@invalid_attrs)
    end

    test "create_account/1 with invalid account_type returns error" do
      attrs = Map.put(@valid_attrs, :account_type, "invalid_type")
      assert {:error, changeset} = Accounts.create_account(attrs)
      assert "is invalid" in errors_on(changeset).account_type
    end

    test "create_account/1 with invalid status returns error" do
      attrs = Map.put(@valid_attrs, :status, "invalid_status")
      assert {:error, changeset} = Accounts.create_account(attrs)
      assert "is invalid" in errors_on(changeset).status
    end

    test "create_account/1 bank_account without bank_name returns error" do
      attrs = @valid_attrs |> Map.delete(:bank_name)
      assert {:error, changeset} = Accounts.create_account(attrs)
      assert "can't be blank" in errors_on(changeset).bank_name
    end

    test "create_account/1 cash_at_hand does not require bank_name" do
      assert {:ok, account} = Accounts.create_account(@cash_attrs)
      assert account.account_type == "cash_at_hand"
      assert account.bank_name == nil
    end

    test "update_account/2 with valid data updates the account" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      update_attrs = %{name: "Updated Bank Account", status: "frozen"}

      assert {:ok, updated} = Accounts.update_account(account, update_attrs)
      assert updated.name == "Updated Bank Account"
      assert updated.status == "frozen"
    end

    test "update_account/2 with invalid data returns error changeset" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Accounts.update_account(account, @invalid_attrs)
      
      # Verify account unchanged
      fetched = Accounts.get_account!(account.id)
      assert fetched.name == account.name
    end

    test "soft_delete_account/1 marks account as deleted" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      assert {:ok, deleted} = Accounts.soft_delete_account(account)
      
      assert deleted.is_deleted == true
      assert deleted.deleted_at != nil
      assert Accounts.list_accounts() == []
    end

    test "restore_account/1 restores a deleted account" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      {:ok, deleted} = Accounts.soft_delete_account(account)
      assert {:ok, restored} = Accounts.restore_account(deleted)
      
      assert restored.is_deleted == false
      assert restored.deleted_at == nil
      assert length(Accounts.list_accounts()) == 1
    end

    test "increase_balance/2 increases account balance and total_cash_in" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      amount = Decimal.new("100.50")

      assert {:ok, updated} = Accounts.increase_balance(account, amount)
      assert Decimal.equal?(updated.current_balance, Decimal.new("100.50"))
      assert Decimal.equal?(updated.total_cash_in, Decimal.new("100.50"))
      assert Decimal.equal?(updated.total_cash_out, Decimal.new("0"))
    end

    test "increase_balance/2 accumulates multiple deposits" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      
      {:ok, updated1} = Accounts.increase_balance(account, Decimal.new("100"))
      {:ok, updated2} = Accounts.increase_balance(updated1, Decimal.new("50"))

      assert Decimal.equal?(updated2.current_balance, Decimal.new("150"))
      assert Decimal.equal?(updated2.total_cash_in, Decimal.new("150"))
    end

    test "decrease_balance/2 decreases account balance and increases total_cash_out" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      {:ok, account} = Accounts.increase_balance(account, Decimal.new("200"))

      assert {:ok, updated} = Accounts.decrease_balance(account, Decimal.new("75.25"))
      assert Decimal.equal?(updated.current_balance, Decimal.new("124.75"))
      assert Decimal.equal?(updated.total_cash_in, Decimal.new("200"))
      assert Decimal.equal?(updated.total_cash_out, Decimal.new("75.25"))
    end

    test "decrease_balance/2 fails when balance would go negative" do
      {:ok, account} = Accounts.create_account(@valid_attrs)
      
      assert {:error, changeset} = Accounts.decrease_balance(account, Decimal.new("50"))
      assert "must be greater than or equal to 0" in errors_on(changeset).current_balance
    end

    test "get_total_balance/0 returns sum of all active account balances" do
      {:ok, account1} = Accounts.create_account(@valid_attrs)
      {:ok, account2} = Accounts.create_account(@cash_attrs)

      {:ok, _} = Accounts.increase_balance(account1, Decimal.new("500"))
      {:ok, _} = Accounts.increase_balance(account2, Decimal.new("250"))

      total = Accounts.get_total_balance()
      assert Decimal.equal?(total, Decimal.new("750"))
    end

    test "get_total_balance/0 excludes deleted accounts" do
      {:ok, account1} = Accounts.create_account(@valid_attrs)
      {:ok, account2} = Accounts.create_account(@cash_attrs)

      {:ok, account1} = Accounts.increase_balance(account1, Decimal.new("500"))
      {:ok, _} = Accounts.increase_balance(account2, Decimal.new("250"))
      {:ok, _} = Accounts.soft_delete_account(account1)

      total = Accounts.get_total_balance()
      assert Decimal.equal?(total, Decimal.new("250"))
    end

    test "get_total_balance/0 excludes non-active accounts" do
      {:ok, account1} = Accounts.create_account(@valid_attrs)
      {:ok, account2} = Accounts.create_account(@cash_attrs)

      {:ok, account1} = Accounts.increase_balance(account1, Decimal.new("500"))
      {:ok, _} = Accounts.increase_balance(account2, Decimal.new("250"))
      {:ok, _} = Accounts.update_account(account1, %{status: "closed"})

      total = Accounts.get_total_balance()
      assert Decimal.equal?(total, Decimal.new("250"))
    end

    test "get_total_balance/0 returns zero when no accounts exist" do
      total = Accounts.get_total_balance()
      assert Decimal.equal?(total, Decimal.new("0"))
    end
  end
end
