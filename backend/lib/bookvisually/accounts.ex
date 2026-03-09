defmodule BookVisually.Accounts do
  @moduledoc """
  The Accounts context.
  Handles all business logic for managing financial accounts and transactions.
  """

  import Ecto.Query, warn: false
  alias BookVisually.Repo
  alias BookVisually.Accounts.FinancialAccount

  @doc """
  Returns the list of active financial accounts.

  ## Examples

      iex> list_accounts()
      [%FinancialAccount{}, ...]

  """
  def list_accounts do
    FinancialAccount.active()
    |> Repo.all()
  end

  @doc """
  Returns the list of accounts by type.

  ## Examples

      iex> list_accounts_by_type("bank_account")
      [%FinancialAccount{}, ...]

  """
  def list_accounts_by_type(account_type) do
    FinancialAccount.active()
    |> FinancialAccount.by_type(account_type)
    |> Repo.all()
  end

  @doc """
  Returns the list of accounts by status.

  ## Examples

      iex> list_accounts_by_status("active")
      [%FinancialAccount{}, ...]

  """
  def list_accounts_by_status(status) do
    FinancialAccount.active()
    |> FinancialAccount.by_status(status)
    |> Repo.all()
  end

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist or is deleted.

  ## Examples

      iex> get_account!(123)
      %FinancialAccount{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id) do
    FinancialAccount.active()
    |> Repo.get!(id)
  end

  @doc """
  Gets a single account, including deleted ones.

  ## Examples

      iex> get_account_with_deleted!(123)
      %FinancialAccount{}

  """
  def get_account_with_deleted!(id) do
    FinancialAccount.with_deleted()
    |> Repo.get!(id)
  end

  @doc """
  Creates a financial account.

  ## Examples

      iex> create_account(%{name: "Main Bank", account_type: "bank_account"})
      {:ok, %FinancialAccount{}}

      iex> create_account(%{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %FinancialAccount{}
    |> FinancialAccount.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a financial account.

  ## Examples

      iex> update_account(account, %{name: "New Name"})
      {:ok, %FinancialAccount{}}

      iex> update_account(account, %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%FinancialAccount{} = account, attrs) do
    account
    |> FinancialAccount.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Soft deletes an account.

  ## Examples

      iex> soft_delete_account(account)
      {:ok, %FinancialAccount{}}

  """
  def soft_delete_account(%FinancialAccount{} = account) do
    account
    |> FinancialAccount.soft_delete_changeset()
    |> Repo.update()
  end

  @doc """
  Restores a soft-deleted account.

  ## Examples

      iex> restore_account(account)
      {:ok, %FinancialAccount{}}

  """
  def restore_account(%FinancialAccount{} = account) do
    account
    |> FinancialAccount.restore_changeset()
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %FinancialAccount{}}

  """
  def change_account(%FinancialAccount{} = account, attrs \\ %{}) do
    FinancialAccount.changeset(account, attrs)
  end

  @doc """
  Increases account balance (for deposits and incoming transfers).

  ## Examples

      iex> increase_balance(account, Decimal.new("100"))
      {:ok, %FinancialAccount{}}

  """
  def increase_balance(%FinancialAccount{} = account, amount) do
    account
    |> FinancialAccount.increase_balance_changeset(amount)
    |> Repo.update()
  end

  @doc """
  Decreases account balance (for withdrawals and outgoing transfers).

  ## Examples

      iex> decrease_balance(account, Decimal.new("50"))
      {:ok, %FinancialAccount{}}

  """
  def decrease_balance(%FinancialAccount{} = account, amount) do
    account
    |> FinancialAccount.decrease_balance_changeset(amount)
    |> Repo.update()
  end

  @doc """
  Gets the total balance across all active accounts.

  ## Examples

      iex> get_total_balance()
      Decimal.new("1000.00")

  """
  def get_total_balance do
    FinancialAccount.active()
    |> FinancialAccount.by_status("active")
    |> select([a], sum(a.current_balance))
    |> Repo.one()
    |> case do
      nil -> Decimal.new("0")
      total -> total
    end
  end
end
