defmodule BookVisuallyWeb.TransactionJSON do
  alias BookVisually.Accounts.AccountTransaction

  @doc """
  Renders a list of transactions.
  """
  def index(%{transactions: transactions}) do
    %{data: for(transaction <- transactions, do: data(transaction))}
  end

  @doc """
  Renders a single transaction.
  """
  def show(%{transaction: transaction}) do
    %{data: data(transaction)}
  end

  defp data(%AccountTransaction{} = transaction) do
    %{
      id: transaction.id,
      transaction_type: transaction.transaction_type,
      amount: transaction.amount,
      description: transaction.description,
      transaction_date: transaction.transaction_date,
      from_account_id: transaction.from_account_id,
      to_account_id: transaction.to_account_id,
      expense_id: transaction.expense_id,
      inserted_at: transaction.inserted_at
    }
  end
end
