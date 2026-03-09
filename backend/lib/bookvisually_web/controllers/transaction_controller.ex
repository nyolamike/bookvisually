defmodule BookVisuallyWeb.TransactionController do
  use BookVisuallyWeb, :controller

  alias BookVisually.Accounts
  alias BookVisually.Accounts.AccountTransaction

  action_fallback BookVisuallyWeb.FallbackController

  def index(conn, params) do
    transactions =
      case params do
        %{"account_id" => account_id} ->
          Accounts.list_transactions_for_account(account_id)

        %{"from_date" => from_date, "to_date" => to_date} ->
          {:ok, from} = Date.from_iso8601(from_date)
          {:ok, to} = Date.from_iso8601(to_date)
          Accounts.list_transactions_by_date_range(from, to)

        _ ->
          Accounts.list_transactions()
      end

    render(conn, :index, transactions: transactions)
  end

  def deposit(conn, %{"to_account_id" => to_account_id, "amount" => amount} = params) do
    transaction_params = %{
      to_account_id: to_account_id,
      amount: amount,
      description: Map.get(params, "description"),
      transaction_date: Map.get(params, "transaction_date", DateTime.utc_now())
    }

    with {:ok, %AccountTransaction{} = transaction} <- Accounts.create_deposit(transaction_params) do
      conn
      |> put_status(:created)
      |> render(:show, transaction: transaction)
    end
  end

  def withdrawal(conn, %{"from_account_id" => from_account_id, "amount" => amount} = params) do
    transaction_params = %{
      from_account_id: from_account_id,
      amount: amount,
      description: Map.get(params, "description"),
      transaction_date: Map.get(params, "transaction_date", DateTime.utc_now())
    }

    with {:ok, %AccountTransaction{} = transaction} <- Accounts.create_withdrawal(transaction_params) do
      conn
      |> put_status(:created)
      |> render(:show, transaction: transaction)
    end
  end

  def transfer(conn, %{"from_account_id" => from_account_id, "to_account_id" => to_account_id, "amount" => amount} = params) do
    transaction_params = %{
      from_account_id: from_account_id,
      to_account_id: to_account_id,
      amount: amount,
      description: Map.get(params, "description"),
      transaction_date: Map.get(params, "transaction_date", DateTime.utc_now())
    }

    with {:ok, %AccountTransaction{} = transaction} <- Accounts.create_transfer(transaction_params) do
      conn
      |> put_status(:created)
      |> render(:show, transaction: transaction)
    end
  end

  def adjustment(conn, %{"account_id" => account_id, "amount" => amount} = params) do
    transaction_params = %{
      from_account_id: if(Decimal.compare(amount, 0) == :lt, do: account_id, else: nil),
      to_account_id: if(Decimal.compare(amount, 0) == :gt, do: account_id, else: nil),
      amount: Decimal.abs(amount),
      description: Map.get(params, "description", "Balance adjustment"),
      transaction_date: Map.get(params, "transaction_date", DateTime.utc_now())
    }

    with {:ok, %AccountTransaction{} = transaction} <- Accounts.create_adjustment(transaction_params) do
      conn
      |> put_status(:created)
      |> render(:show, transaction: transaction)
    end
  end
end
