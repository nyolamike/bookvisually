defmodule BookVisually.Resources.SupplyResourceProperties do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:resource_id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  @valid_statuses ["in_stock", "low_stock", "out_of_stock"]

  schema "supply_resource_properties" do
    belongs_to :resource, BookVisually.Resources.Resource,
      foreign_key: :resource_id,
      define_field: false

    field :issues_out_of_stock_alerts, :boolean, default: false
    field :out_of_stock_alert_quantity, :decimal
    field :current_stock_quantity, :decimal, default: Decimal.new("0")
    field :status, :string, default: "in_stock"
    field :notes, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(properties, attrs) do
    properties
    |> cast(attrs, [
      :resource_id,
      :issues_out_of_stock_alerts,
      :out_of_stock_alert_quantity,
      :current_stock_quantity,
      :status,
      :notes
    ])
    |> validate_required([:resource_id])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:current_stock_quantity, greater_than_or_equal_to: 0)
    |> validate_number(:out_of_stock_alert_quantity, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:resource_id)
  end

  @doc """
  Updates stock quantity and automatically sets status based on alert threshold
  """
  def update_stock_changeset(properties, new_quantity) do
    new_status = determine_status(new_quantity, properties.out_of_stock_alert_quantity)

    properties
    |> change(%{
      current_stock_quantity: new_quantity,
      status: new_status
    })
  end

  defp determine_status(quantity, alert_threshold) do
    cond do
      Decimal.equal?(quantity, 0) -> "out_of_stock"
      not is_nil(alert_threshold) and Decimal.lt?(quantity, alert_threshold) -> "low_stock"
      true -> "in_stock"
    end
  end
end
