defmodule BookVisually.Accounts.AccountTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_transaction_types [
    "deposit",      # Money coming in (investment, revenue, etc.)
    "withdrawal",   # Money going out (expenses, transfers out)
    "transfer",     # Money moving between accounts
    "expense",      # Payment for an expense
    "income",       # Revenue/income received
    "adjustment"    # Balance correction
  ]

  schema "account_transactions" do
    field :transaction_type, :string
    field :transaction_date, :utc_datetime
    field :amount, :decimal
    field :reference_number, :string
    field :description, :string
    field :initiated_by_user_id, :integer, default: 1
    field :notes, :string

    belongs_to :from_account, BookVisually.Accounts.FinancialAccount
    belongs_to :to_account, BookVisually.Accounts.FinancialAccount
    belongs_to :expense, BookVisually.Expenses.Expense

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Order by date descending
  """
  def order_by_date_desc(query \\ __MODULE__) do
    from t in query, order_by: [desc: t.transaction_date]
  end

  @doc """
  Filter by account (either from or to)
  """
  def by_account(query \\ __MODULE__, account_id) do
    from t in query,
      where: t.from_account_id == ^account_id or t.to_account_id == ^account_id
  end

  @doc """
  Filter by date range
  """
  def by_date_range(query \\ __MODULE__, start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    end_datetime = DateTime.new!(end_date, ~T[23:59:59])

    from t in query,
      where: t.transaction_date >= ^start_datetime and t.transaction_date <= ^end_datetime
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :transaction_type,
      :transaction_date,
      :amount,
      :from_account_id,
      :to_account_id,
      :expense_id,
      :reference_number,
      :description,
      :initiated_by_user_id,
      :notes
    ])
    |> validate_required([:transaction_type, :amount])
    |> validate_inclusion(:transaction_type, @valid_transaction_types)
    |> validate_number(:amount, greater_than: 0)
    |> put_transaction_date_if_missing()
    |> validate_account_usage()
    |> foreign_key_constraint(:from_account_id)
    |> foreign_key_constraint(:to_account_id)
    |> foreign_key_constraint(:expense_id)
  end

  defp put_transaction_date_if_missing(changeset) do
    if get_field(changeset, :transaction_date) do
      changeset
    else
      put_change(changeset, :transaction_date, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end

  defp validate_account_usage(changeset) do
    transaction_type = get_field(changeset, :transaction_type)
    from_account = get_field(changeset, :from_account_id)
    to_account = get_field(changeset, :to_account_id)
    expense_id = get_field(changeset, :expense_id)

    case transaction_type do
      "deposit" ->
        if is_nil(to_account) do
          add_error(changeset, :to_account_id, "is required for deposits")
        else
          changeset
        end

      "withdrawal" ->
        if is_nil(from_account) do
          add_error(changeset, :from_account_id, "is required for withdrawals")
        else
          changeset
        end

      "transfer" ->
        cond do
          is_nil(from_account) ->
            add_error(changeset, :from_account_id, "is required for transfers")
          is_nil(to_account) ->
            add_error(changeset, :to_account_id, "is required for transfers")
          from_account == to_account ->
            add_error(changeset, :to_account_id, "cannot be the same as from_account")
          true ->
            changeset
        end

      "expense" ->
        cond do
          is_nil(from_account) ->
            add_error(changeset, :from_account_id, "is required for expense payments")
          is_nil(expense_id) ->
            add_error(changeset, :expense_id, "is required for expense payments")
          true ->
            changeset
        end

      "income" ->
        if is_nil(to_account) do
          add_error(changeset, :to_account_id, "is required for income")
        else
          changeset
        end

      "adjustment" ->
        changeset

      _ ->
        changeset
    end
  end
end
