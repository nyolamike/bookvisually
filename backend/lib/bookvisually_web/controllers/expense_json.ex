defmodule BookVisuallyWeb.ExpenseJSON do
  alias BookVisually.Expenses.Expense

  @doc """
  Renders a list of expenses.
  """
  def index(%{expenses: expenses}) do
    %{data: for(expense <- expenses, do: data(expense))}
  end

  @doc """
  Renders a single expense.
  """
  def show(%{expense: expense}) do
    %{data: data(expense)}
  end

  @doc """
  Renders expense with payment transaction and stock movement.
  """
  def show_with_payment(%{expense: expense, transaction: transaction, movement: movement}) do
    %{
      data: %{
        expense: data(expense),
        transaction: %{
          id: transaction.id,
          amount: transaction.amount,
          from_account_id: transaction.from_account_id,
          transaction_date: transaction.transaction_date
        },
        stock_movement: if(movement, do: %{
          id: movement.id,
          quantity_change: movement.quantity_change,
          stock_after_movement: movement.stock_after_movement
        }, else: nil)
      }
    }
  end

  defp data(%Expense{} = expense) do
    %{
      id: expense.id,
      resource_id: expense.resource_id,
      expense_date: expense.expense_date,
      unit_cost: expense.unit_cost,
      quantity: expense.quantity,
      unit_of_measure: expense.unit_of_measure,
      total_amount: expense.total_amount,
      description: expense.description,
      notes: expense.notes,
      inserted_at: expense.inserted_at
    }
  end
end
