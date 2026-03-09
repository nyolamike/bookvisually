defmodule BookVisually.Resources.UtilityResourceProperties do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:resource_id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  @valid_bill_types ["utility", "service", "salary", "rent", "other"]
  @valid_bill_statuses ["paid", "unpaid", "partially_paid", "overdue"]

  schema "utility_resource_properties" do
    belongs_to :resource, BookVisually.Resources.Resource,
      foreign_key: :resource_id,
      define_field: false

    field :bill_type, :string
    field :billing_cycle_days, :integer

    # Alert settings
    field :issues_bill_due_alerts, :boolean, default: false
    field :days_to_due_date_alert, :integer

    # Current bill status (cached for performance)
    field :current_bill_status, :string, default: "paid"
    field :last_bill_date, :date
    field :next_bill_due_date, :date
    field :current_bill_quantity_consumed, :decimal

    field :notes, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(properties, attrs) do
    properties
    |> cast(attrs, [
      :resource_id,
      :bill_type,
      :billing_cycle_days,
      :issues_bill_due_alerts,
      :days_to_due_date_alert,
      :current_bill_status,
      :last_bill_date,
      :next_bill_due_date,
      :current_bill_quantity_consumed,
      :notes
    ])
    |> validate_required([:resource_id, :bill_type])
    |> validate_inclusion(:bill_type, @valid_bill_types)
    |> validate_inclusion(:current_bill_status, @valid_bill_statuses)
    |> validate_number(:billing_cycle_days, greater_than: 0)
    |> validate_number(:days_to_due_date_alert, greater_than_or_equal_to: 0)
    |> validate_number(:current_bill_quantity_consumed, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:resource_id)
  end

  @doc """
  Updates bill status
  """
  def update_status_changeset(properties, new_status) do
    properties
    |> change(%{current_bill_status: new_status})
    |> validate_inclusion(:current_bill_status, @valid_bill_statuses)
  end

  @doc """
  Updates bill dates
  """
  def update_dates_changeset(properties, last_date, next_date) do
    properties
    |> change(%{
      last_bill_date: last_date,
      next_bill_due_date: next_date
    })
  end

  @doc """
  Updates consumption quantity
  """
  def update_consumption_changeset(properties, quantity) do
    properties
    |> change(%{current_bill_quantity_consumed: quantity})
    |> validate_number(:current_bill_quantity_consumed, greater_than_or_equal_to: 0)
  end
end
