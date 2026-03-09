defmodule BookVisually.Expenses.Expense do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "expenses" do
    belongs_to :resource, BookVisually.Resources.Resource
    belongs_to :paid_from_account, BookVisually.Accounts.FinancialAccount

    field :expense_date, :date
    field :unit_cost, :decimal
    field :quantity, :decimal
    field :unit_of_measure, :string
    field :total_amount, :decimal
    field :description, :string

    # Metadata
    field :payment_method, :string
    field :reference_number, :string
    field :notes, :string

    field :is_deleted, :boolean, default: false
    field :deleted_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  Default scope - returns only active (non-deleted) expenses
  """
  def active(query \\ __MODULE__) do
    from e in query, where: e.is_deleted == false
  end

  @doc """
  Include deleted expenses
  """
  def with_deleted(query \\ __MODULE__) do
    query
  end

  @doc """
  Filter by resource
  """
  def by_resource(query \\ __MODULE__, resource_id) do
    from e in query, where: e.resource_id == ^resource_id
  end

  @doc """
  Filter by date range
  """
  def by_date_range(query \\ __MODULE__, start_date, end_date) do
    from e in query,
      where: e.expense_date >= ^start_date and e.expense_date <= ^end_date
  end

  @doc """
  Order by date descending
  """
  def order_by_date_desc(query \\ __MODULE__) do
    from e in query, order_by: [desc: e.expense_date]
  end

  @doc false
  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [
      :resource_id,
      :paid_from_account_id,
      :expense_date,
      :unit_cost,
      :quantity,
      :unit_of_measure,
      :total_amount,
      :description,
      :payment_method,
      :reference_number,
      :notes
    ])
    |> validate_required([:resource_id, :expense_date])
    |> calculate_total_if_needed()
    |> validate_required([:total_amount])
    |> validate_number(:total_amount, greater_than_or_equal_to: 0)
    |> validate_number(:unit_cost, greater_than_or_equal_to: 0)
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:resource_id)
    |> foreign_key_constraint(:paid_from_account_id)
  end

  defp calculate_total_if_needed(changeset) do
    unit_cost = get_change(changeset, :unit_cost)
    quantity = get_change(changeset, :quantity)
    total = get_change(changeset, :total_amount)

    # If unit_cost and quantity are provided but total is not, calculate it
    if not is_nil(unit_cost) and not is_nil(quantity) and is_nil(total) do
      calculated_total = Decimal.mult(unit_cost, quantity)
      put_change(changeset, :total_amount, calculated_total)
    else
      changeset
    end
  end

  @doc """
  Changeset for soft delete
  """
  def soft_delete_changeset(expense) do
    expense
    |> change(%{
      is_deleted: true,
      deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  @doc """
  Changeset for restore
  """
  def restore_changeset(expense) do
    expense
    |> change(%{
      is_deleted: false,
      deleted_at: nil
    })
  end
end
