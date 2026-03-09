defmodule BookVisually.Resources.SubscriptionResourceProperties do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:resource_id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  @valid_statuses ["active", "expired", "cancelled"]

  schema "subscription_resource_properties" do
    belongs_to :resource, BookVisually.Resources.Resource,
      foreign_key: :resource_id,
      define_field: false

    field :renewal_period, :string
    field :vendor, :string
    field :package, :string

    # Alert settings
    field :issues_expiry_alerts, :boolean, default: false
    field :days_left_to_alert, :integer

    # Current subscription (cached for performance)
    field :current_subscription_start_date, :date
    field :current_subscription_end_date, :date

    # Status
    field :status, :string, default: "active"

    field :notes, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(properties, attrs) do
    properties
    |> cast(attrs, [
      :resource_id,
      :renewal_period,
      :vendor,
      :package,
      :issues_expiry_alerts,
      :days_left_to_alert,
      :current_subscription_start_date,
      :current_subscription_end_date,
      :status,
      :notes
    ])
    |> validate_required([:resource_id, :vendor, :package])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:days_left_to_alert, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:resource_id)
  end

  @doc """
  Updates subscription period and sets status to active
  """
  def update_period_changeset(properties, start_date, end_date) do
    properties
    |> change(%{
      current_subscription_start_date: start_date,
      current_subscription_end_date: end_date,
      status: "active"
    })
  end

  @doc """
  Expires the subscription
  """
  def expire_changeset(properties) do
    properties
    |> change(%{status: "expired"})
  end

  @doc """
  Cancels the subscription
  """
  def cancel_changeset(properties) do
    properties
    |> change(%{status: "cancelled"})
  end
end
