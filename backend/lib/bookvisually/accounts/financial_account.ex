defmodule BookVisually.Accounts.FinancialAccount do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_account_types ["cash_at_hand", "bank_account", "funding_line"]
  @valid_statuses ["active", "closed", "frozen"]

  schema "financial_accounts" do
    field :name, :string
    field :description, :string
    field :account_type, :string

    # Current balance (cached for performance)
    field :current_balance, :decimal, default: Decimal.new("0")

    # Totals (cached for performance)
    field :total_cash_in, :decimal, default: Decimal.new("0")
    field :total_cash_out, :decimal, default: Decimal.new("0")

    # Bank account specific fields
    field :bank_name, :string
    field :account_number, :string

    # Status
    field :status, :string, default: "active"

    field :notes, :string
    field :is_deleted, :boolean, default: false
    field :deleted_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  Default scope - returns only active (non-deleted) accounts
  """
  def active(query \\ __MODULE__) do
    from a in query, where: a.is_deleted == false
  end

  @doc """
  Include deleted accounts
  """
  def with_deleted(query \\ __MODULE__) do
    query
  end

  @doc """
  Filter by account type
  """
  def by_type(query \\ __MODULE__, account_type) when account_type in @valid_account_types do
    from a in query, where: a.account_type == ^account_type
  end

  @doc """
  Filter by status
  """
  def by_status(query \\ __MODULE__, status) when status in @valid_statuses do
    from a in query, where: a.status == ^status
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :name,
      :description,
      :account_type,
      :current_balance,
      :total_cash_in,
      :total_cash_out,
      :bank_name,
      :account_number,
      :status,
      :notes
    ])
    |> validate_required([:name, :account_type])
    |> validate_inclusion(:account_type, @valid_account_types)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:current_balance, greater_than_or_equal_to: 0)
    |> validate_number(:total_cash_in, greater_than_or_equal_to: 0)
    |> validate_number(:total_cash_out, greater_than_or_equal_to: 0)
    |> validate_bank_account_fields()
  end

  defp validate_bank_account_fields(changeset) do
    account_type = get_field(changeset, :account_type)

    if account_type == "bank_account" do
      changeset
      |> validate_required([:bank_name])
    else
      changeset
    end
  end

  @doc """
  Changeset for soft delete
  """
  def soft_delete_changeset(account) do
    account
    |> change(%{
      is_deleted: true,
      deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  @doc """
  Changeset for restore
  """
  def restore_changeset(account) do
    account
    |> change(%{
      is_deleted: false,
      deleted_at: nil
    })
  end

  @doc """
  Changeset for updating balance (increase)
  """
  def increase_balance_changeset(account, amount) do
    new_balance = Decimal.add(account.current_balance, amount)
    new_cash_in = Decimal.add(account.total_cash_in, amount)

    account
    |> change(%{
      current_balance: new_balance,
      total_cash_in: new_cash_in
    })
    |> validate_number(:current_balance, greater_than_or_equal_to: 0)
  end

  @doc """
  Changeset for updating balance (decrease)
  """
  def decrease_balance_changeset(account, amount) do
    new_balance = Decimal.sub(account.current_balance, amount)
    new_cash_out = Decimal.add(account.total_cash_out, amount)

    account
    |> change(%{
      current_balance: new_balance,
      total_cash_out: new_cash_out
    })
    |> validate_number(:current_balance, greater_than_or_equal_to: 0)
  end
end
