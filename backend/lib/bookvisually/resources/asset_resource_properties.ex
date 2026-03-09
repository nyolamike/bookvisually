defmodule BookVisually.Resources.AssetResourceProperties do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:resource_id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  @valid_depreciation_methods ["straight_line", "declining_balance", "none"]
  @valid_warranty_statuses ["na", "active", "used", "expired"]
  @valid_guarantee_statuses ["na", "active", "used", "expired"]
  @valid_statuses ["okay", "in_use", "offsite", "damaged", "destroyed", "disposed"]

  schema "asset_resource_properties" do
    belongs_to :resource, BookVisually.Resources.Resource,
      foreign_key: :resource_id,
      define_field: false

    # Purchase info
    field :purchase_date, :date
    field :purchase_cost, :decimal

    # Depreciation
    field :depreciation_method, :string
    field :depreciation_rate, :decimal
    field :current_value, :decimal

    # Warranty
    field :has_warranty, :boolean, default: false
    field :warranty_expiry_date, :date
    field :warranty_status, :string, default: "na"

    # Guarantee
    field :has_guarantee, :boolean, default: false
    field :guarantee_expiry_date, :date
    field :guarantee_status, :string, default: "na"

    # Asset status
    field :status, :string, default: "okay"

    field :notes, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(properties, attrs) do
    properties
    |> cast(attrs, [
      :resource_id,
      :purchase_date,
      :purchase_cost,
      :depreciation_method,
      :depreciation_rate,
      :current_value,
      :has_warranty,
      :warranty_expiry_date,
      :warranty_status,
      :has_guarantee,
      :guarantee_expiry_date,
      :guarantee_status,
      :status,
      :notes
    ])
    |> validate_required([:resource_id, :purchase_date, :purchase_cost])
    |> validate_inclusion(:depreciation_method, @valid_depreciation_methods)
    |> validate_inclusion(:warranty_status, @valid_warranty_statuses)
    |> validate_inclusion(:guarantee_status, @valid_guarantee_statuses)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:purchase_cost, greater_than: 0)
    |> validate_number(:current_value, greater_than_or_equal_to: 0)
    |> validate_number(:depreciation_rate, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> foreign_key_constraint(:resource_id)
  end

  @doc """
  Updates the current value of the asset
  """
  def update_value_changeset(properties, new_value) do
    properties
    |> change(%{current_value: new_value})
    |> validate_number(:current_value, greater_than_or_equal_to: 0)
  end

  @doc """
  Updates warranty status
  """
  def update_warranty_status_changeset(properties, new_status) do
    properties
    |> change(%{warranty_status: new_status})
    |> validate_inclusion(:warranty_status, @valid_warranty_statuses)
  end

  @doc """
  Updates guarantee status
  """
  def update_guarantee_status_changeset(properties, new_status) do
    properties
    |> change(%{guarantee_status: new_status})
    |> validate_inclusion(:guarantee_status, @valid_guarantee_statuses)
  end
end
