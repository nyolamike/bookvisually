defmodule BookVisuallyWeb.ExpenseController do
  use BookVisuallyWeb, :controller

  alias BookVisually.Expenses
  alias BookVisually.Accounts
  alias BookVisually.Supplies
  alias BookVisually.Repo

  action_fallback BookVisuallyWeb.FallbackController

  def index(conn, params) do
    expenses =
      case params do
        %{"resource_id" => resource_id} ->
          Expenses.list_expenses_by_resource(resource_id)

        %{"from_date" => from_date, "to_date" => to_date} ->
          {:ok, from} = Date.from_iso8601(from_date)
          {:ok, to} = Date.from_iso8601(to_date)
          Expenses.list_expenses_by_date_range(from, to)

        _ ->
          Expenses.list_expenses()
      end

    render(conn, :index, expenses: expenses)
  end

  def show(conn, %{"id" => id}) do
    expense = Expenses.get_expense!(id)
    render(conn, :show, expense: expense)
  end

  @doc """
  Batch operation: Create expense + payment transaction + update stock (if supply).
  This is the key operation for the visual workflow where money flows from account
  to expense and stock updates happen atomically.
  """
  def create_with_payment(conn, params) do
    result =
      Repo.transaction(fn ->
        # Step 1: Create the expense
        expense_params = %{
          resource_id: params["resource_id"],
          expense_date: params["expense_date"] || Date.utc_today(),
          unit_cost: params["unit_cost"],
          quantity: params["quantity"],
          unit_of_measure: params["unit_of_measure"],
          description: params["description"],
          notes: params["notes"]
        }

        with {:ok, expense} <- Expenses.create_expense(expense_params),
             # Step 2: Create payment transaction
             transaction_params = %{
               from_account_id: params["paid_from_account_id"],
               amount: expense.total_amount,
               description: params["description"] || "Expense payment",
               transaction_date: params["transaction_date"] || DateTime.utc_now(),
               expense_id: expense.id
             },
             {:ok, transaction} <- Accounts.create_expense_payment(transaction_params),
             # Step 3: If it's a supply, create stock movement
             {:ok, movement} <- maybe_create_stock_movement(params, expense) do
          {expense, transaction, movement}
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)

    case result do
      {:ok, {expense, transaction, movement}} ->
        conn
        |> put_status(:created)
        |> render(:show_with_payment, expense: expense, transaction: transaction, movement: movement)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp maybe_create_stock_movement(%{"resource_id" => resource_id, "quantity" => quantity} = params, expense) do
    # Check if this is a supply resource
    case BookVisually.Resources.get_resource!(resource_id) do
      %{resource_category: "supply"} ->
        movement_params = %{
          supply_resource_id: resource_id,
          movement_type: "purchase",
          quantity_change: quantity,
          movement_date: params["expense_date"] || Date.utc_today(),
          expense_id: expense.id,
          description: params["description"]
        }

        Supplies.create_stock_movement(movement_params)

      _ ->
        {:ok, nil}
    end
  end
end
