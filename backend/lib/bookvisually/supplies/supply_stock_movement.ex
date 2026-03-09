defmodule BookVisually.Supplies.SupplyStockMovement do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_movement_types ["purchase", "usage", "adjustment", "disposal", "return"]

  schema "supply_stock_movements" do
    belongs_to :resource, BookVisually.Resources.Resource
    belongs_to :expense, BookVisually.Expenses.Expense

    field :movement_type, :string
    field :movement_date, :utc_datetime

    # Quantity change (positive = increase, negative = decrease)
    field :quantity_change, :decimal
    field :unit_of_measure, :string

    # Stock level after this movement (cached for performance)
    field :stock_after_movement, :decimal

    # Who used it (for usage tracking)
    field :used_by, :string

    field :description, :string

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Order by date descending
  """
  def order_by_date_desc(query \\ __MODULE__) do
    from m in query, order_by: [desc: m.movement_date]
  end

  @doc """
  Filter by resource
  """
  def by_resource(query \\ __MODULE__, resource_id) do
    from m in query, where: m.resource_id == ^resource_id
  end

  @doc """
  Filter by movement type
  """
  def by_type(query \\ __MODULE__, movement_type) when movement_type in @valid_movement_types do
    from m in query, where: m.movement_type == ^movement_type
  end

  @doc """
  Filter by date range
  """
  def by_date_range(query \\ __MODULE__, start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    end_datetime = DateTime.new!(end_date, ~T[23:59:59])

    from m in query,
      where: m.movement_date >= ^start_datetime and m.movement_date <= ^end_datetime
  end

  @doc false
  def changeset(movement, attrs) do
    movement
    |> cast(attrs, [
      :resource_id,
      :expense_id,
      :movement_type,
      :movement_date,
      :quantity_change,
      :unit_of_measure,
      :stock_after_movement,
      :used_by,
      :description
    ])
    |> validate_required([:resource_id, :movement_type, :quantity_change, :stock_after_movement])
    |> validate_inclusion(:movement_type, @valid_movement_types)
    |> validate_quantity_change_not_zero()
    |> validate_number(:stock_after_movement, greater_than_or_equal_to: 0)
    |> put_movement_date_if_missing()
    |> foreign_key_constraint(:resource_id)
    |> foreign_key_constraint(:expense_id)
  end

  defp validate_quantity_change_not_zero(changeset) do
    quantity_change = get_field(changeset, :quantity_change)

    if quantity_change && Decimal.equal?(quantity_change, 0) do
      add_error(changeset, :quantity_change, "cannot be zero")
    else
      changeset
    end
  end

  defp put_movement_date_if_missing(changeset) do
    if get_field(changeset, :movement_date) do
      changeset
    else
      put_change(changeset, :movement_date, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end
end
