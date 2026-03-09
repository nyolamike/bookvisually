defmodule BookVisuallyWeb.AccountJSON do
  alias BookVisually.Accounts.FinancialAccount

  @doc """
  Renders a list of accounts.
  """
  def index(%{accounts: accounts}) do
    %{data: for(account <- accounts, do: data(account))}
  end

  @doc """
  Renders a single account.
  """
  def show(%{account: account}) do
    %{data: data(account)}
  end

  @doc """
  Renders account history.
  """
  def history(%{account: account, transactions: transactions}) do
    %{
      data: %{
        account: data(account),
        transactions: transactions
      }
    }
  end

  defp data(%FinancialAccount{} = account) do
    %{
      id: account.id,
      name: account.name,
      account_type: account.account_type,
      current_balance: account.current_balance,
      total_cash_in: account.total_cash_in,
      total_cash_out: account.total_cash_out,
      status: account.status,
      bank_name: account.bank_name,
      account_number: account.account_number,
      inserted_at: account.inserted_at,
      updated_at: account.updated_at
    }
  end
end
