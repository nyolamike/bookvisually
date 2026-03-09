defmodule BookVisually.Bills.UtilityBill do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_statuses ["unpaid", "partially_paid", "paid", "overdue", "cancelled"]

  schema "utility_bills" do
    belongs_to :resource, BookVisually.Resources.Resource

    field :bill_date, :date
    field :due_date, :date

    # Meter/reading fields
    field :bill_reading, :decimal
    field :previous_reading, :decimal
    field :quantity_consumed, :decimal
    field :unit_of_measure, :string

    field :unit_cost, :decimal
    field :total_amount, :decimal

    field :vendor, :string
    field :reference_number, :string
    field :status, :string, default: "unpaid"
    field :notes, :string

    field :is_deleted, :boolean, default: false
    field :deleted_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  Default scope - returns only active (non-deleted) bills
  """
  def active(query \\ __MODULE__) do
    from b in query, where: b.is_deleted == false
  end

  @doc """
  Include deleted bills
  """
  def with_deleted(query \\ __MODULE__) do
    query
  end

  @doc """
  Filter by resource
  """
  def by_resource(query \\ __MODULE__, resource_id) do
    from b in query, where: b.resource_id == ^resource_id
  end

  @doc """
  Filter by status
  """
  def by_status(query \\ __MODULE__, status) when status in @valid_statuses do
    from b in query, where: b.status == ^status
  end

  @doc """
  Filter unpaid bills (unpaid or partially_paid)
  """
  def unpaid(query \\ __MODULE__) do
    from b in query, where: b.status in ["unpaid", "partially_paid"]
  end

  @doc """
  Filter overdue bills
  """
  def overdue(query \\ __MODULE__) do
    from b in query, where: b.status == "overdue"
  end

  @doc """
  Order by due date ascending
  """
  def order_by_due_date(query \\ __MODULE__) do
    from b in query, order_by: [asc: b.due_date]
  end

  @doc false
  def changeset(bill, attrs) do
    bill
    |> cast(attrs, [
      :resource_id,
      :bill_date,
      :due_date,
      :bill_reading,
      :previous_reading,
      :quantity_consumed,
      :unit_of_measure,
      :unit_cost,
      :total_amount,
      :vendor,
      :reference_number,
      :status,
      :notes
    ])
    |> validate_required([:bill_date, :total_amount])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:total_amount, greater_than_or_equal_to: 0)
    |> validate_number(:unit_cost, greater_than_or_equal_to: 0)
    |> validate_number(:quantity_consumed, greater_than_or_equal_to: 0)
    |> validate_due_date()
    |> calculate_consumption_if_needed()
    |> foreign_key_constraint(:resource_id)
  end

  defp validate_due_date(changeset) do
    bill_date = get_field(changeset, :bill_date)
    due_date = get_field(changeset, :due_date)

    if bill_date && due_date && Date.compare(due_date, bill_date) == :lt do
      add_error(changeset, :due_date, "must be on or after bill date")
    else
      changeset
    end
  end

  defp calculate_consumption_if_needed(changeset) do
    bill_reading = get_change(changeset, :bill_reading)
    previous_reading = get_change(changeset, :previous_reading)
    quantity_consumed = get_change(changeset, :quantity_consumed)

    # If readings are provided but consumption is not, calculate it
    if not is_nil(bill_reading) and not is_nil(previous_reading) and is_nil(quantity_consumed) do
      calculated = Decimal.sub(bill_reading, previous_reading)
      put_change(changeset, :quantity_consumed, calculated)
    else
      changeset
    end
  end

  @doc """
  Changeset for soft delete
  """
  def soft_delete_changeset(bill) do
    bill
    |> change(%{
      is_deleted: true,
      deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  @doc """
  Changeset for restore
  """
  def restore_changeset(bill) do
    bill
    |> change(%{
      is_deleted: false,
      deleted_at: nil
    })
  end

  @doc """
  Changeset for updating status
  """
  def update_status_changeset(bill, new_status) do
    bill
    |> change(%{status: new_status})
    |> validate_inclusion(:status, @valid_statuses)
  end
end
