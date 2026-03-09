defmodule BookVisually.ExpensesTest do
  use BookVisually.DataCase

  alias BookVisually.Expenses
  alias BookVisually.Resources
  alias BookVisually.Accounts

  describe "expenses" do
    setup do
      {:ok, resource} = Resources.create_resource(%{
        name: "Generator Fuel",
        resource_category: "supply",
        default_unit_of_measure: "liters"
      })

      {:ok, account} = Accounts.create_account(%{
        name: "Cash at Hand",
        account_type: "cash_at_hand"
      })

      %{resource: resource, account: account}
    end

    @valid_attrs %{
      expense_date: ~D[2026-03-08],
      unit_cost: Decimal.new("2.50"),
      quantity: Decimal.new("100"),
      unit_of_measure: "liters",
      description: "Fuel purchase for generator"
    }

    @invalid_attrs %{
      resource_id: nil,
      expense_date: nil,
      total_amount: nil
    }

    test "list_expenses/0 returns all active expenses", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, expense} = Expenses.create_expense(attrs)
      
      expenses = Expenses.list_expenses()
      assert length(expenses) == 1
      assert hd(expenses).id == expense.id
    end

    test "list_expenses/0 does not return deleted expenses", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, expense} = Expenses.create_expense(attrs)
      {:ok, _deleted} = Expenses.soft_delete_expense(expense)
      
      expenses = Expenses.list_expenses()
      assert expenses == []
    end

    test "list_expenses_by_resource/1 filters by resource", %{resource: resource} do
      {:ok, other_resource} = Resources.create_resource(%{
        name: "Water",
        resource_category: "utility"
      })

      attrs1 = Map.put(@valid_attrs, :resource_id, resource.id)
      attrs2 = Map.put(@valid_attrs, :resource_id, other_resource.id)
      
      {:ok, expense1} = Expenses.create_expense(attrs1)
      {:ok, _expense2} = Expenses.create_expense(attrs2)

      expenses = Expenses.list_expenses_by_resource(resource.id)
      assert length(expenses) == 1
      assert hd(expenses).id == expense1.id
    end

    test "list_expenses_by_date_range/2 filters by date range", %{resource: resource} do
      attrs1 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:expense_date, ~D[2026-03-01])
      attrs2 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:expense_date, ~D[2026-03-15])
      attrs3 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:expense_date, ~D[2026-03-31])

      {:ok, _expense1} = Expenses.create_expense(attrs1)
      {:ok, expense2} = Expenses.create_expense(attrs2)
      {:ok, _expense3} = Expenses.create_expense(attrs3)

      expenses = Expenses.list_expenses_by_date_range(~D[2026-03-10], ~D[2026-03-20])
      assert length(expenses) == 1
      assert hd(expenses).id == expense2.id
    end

    test "get_expense!/1 returns the expense with given id", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, expense} = Expenses.create_expense(attrs)
      
      fetched = Expenses.get_expense!(expense.id)
      assert fetched.id == expense.id
    end

    test "get_expense!/1 raises when expense is deleted", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, expense} = Expenses.create_expense(attrs)
      {:ok, _deleted} = Expenses.soft_delete_expense(expense)

      assert_raise Ecto.NoResultsError, fn ->
        Expenses.get_expense!(expense.id)
      end
    end

    test "create_expense/1 with valid data creates an expense", %{resource: resource, account: account} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:paid_from_account_id, account.id)

      assert {:ok, expense} = Expenses.create_expense(attrs)
      assert expense.resource_id == resource.id
      assert expense.paid_from_account_id == account.id
      assert expense.expense_date == ~D[2026-03-08]
      assert Decimal.equal?(expense.unit_cost, Decimal.new("2.50"))
      assert Decimal.equal?(expense.quantity, Decimal.new("100"))
      assert expense.unit_of_measure == "liters"
      assert Decimal.equal?(expense.total_amount, Decimal.new("250.00"))
    end

    test "create_expense/1 calculates total from unit_cost and quantity", %{resource: resource} do
      attrs = %{
        resource_id: resource.id,
        expense_date: ~D[2026-03-08],
        unit_cost: Decimal.new("5.00"),
        quantity: Decimal.new("20")
      }

      assert {:ok, expense} = Expenses.create_expense(attrs)
      assert Decimal.equal?(expense.total_amount, Decimal.new("100.00"))
    end

    test "create_expense/1 uses provided total_amount if given", %{resource: resource} do
      attrs = %{
        resource_id: resource.id,
        expense_date: ~D[2026-03-08],
        unit_cost: Decimal.new("5.00"),
        quantity: Decimal.new("20"),
        total_amount: Decimal.new("95.00")
      }

      assert {:ok, expense} = Expenses.create_expense(attrs)
      assert Decimal.equal?(expense.total_amount, Decimal.new("95.00"))
    end

    test "create_expense/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Expenses.create_expense(@invalid_attrs)
    end

    test "create_expense/1 with negative total_amount returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:total_amount, Decimal.new("-50"))

      assert {:error, changeset} = Expenses.create_expense(attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).total_amount
    end

    test "update_expense/2 with valid data updates the expense", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, expense} = Expenses.create_expense(attrs)

      update_attrs = %{description: "Updated description", payment_method: "cash"}
      assert {:ok, updated} = Expenses.update_expense(expense, update_attrs)
      assert updated.description == "Updated description"
      assert updated.payment_method == "cash"
    end

    test "soft_delete_expense/1 marks expense as deleted", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, expense} = Expenses.create_expense(attrs)
      
      assert {:ok, deleted} = Expenses.soft_delete_expense(expense)
      assert deleted.is_deleted == true
      assert deleted.deleted_at != nil
      assert Expenses.list_expenses() == []
    end

    test "restore_expense/1 restores a deleted expense", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, expense} = Expenses.create_expense(attrs)
      {:ok, deleted} = Expenses.soft_delete_expense(expense)
      
      assert {:ok, restored} = Expenses.restore_expense(deleted)
      assert restored.is_deleted == false
      assert restored.deleted_at == nil
      assert length(Expenses.list_expenses()) == 1
    end

    test "get_total_for_resource/1 returns sum of expenses for resource", %{resource: resource} do
      attrs1 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:total_amount, Decimal.new("100"))
      attrs2 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:total_amount, Decimal.new("150"))

      {:ok, _} = Expenses.create_expense(attrs1)
      {:ok, _} = Expenses.create_expense(attrs2)

      total = Expenses.get_total_for_resource(resource.id)
      assert Decimal.equal?(total, Decimal.new("250"))
    end

    test "get_total_for_date_range/2 returns sum of expenses in date range", %{resource: resource} do
      attrs1 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:expense_date, ~D[2026-03-01]) |> Map.put(:total_amount, Decimal.new("100"))
      attrs2 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:expense_date, ~D[2026-03-15]) |> Map.put(:total_amount, Decimal.new("150"))
      attrs3 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:expense_date, ~D[2026-03-31]) |> Map.put(:total_amount, Decimal.new("200"))

      {:ok, _} = Expenses.create_expense(attrs1)
      {:ok, _} = Expenses.create_expense(attrs2)
      {:ok, _} = Expenses.create_expense(attrs3)

      total = Expenses.get_total_for_date_range(~D[2026-03-10], ~D[2026-03-20])
      assert Decimal.equal?(total, Decimal.new("150"))
    end
  end
end
