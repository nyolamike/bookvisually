defmodule BookVisually.Resources.Resource do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_categories ["subscription", "utility", "supply", "asset"]

  schema "resources" do
    field :name, :string
    field :description, :string
    field :resource_category, :string
    field :default_unit_of_measure, :string
    field :default_unit_cost, :decimal

    # Inspection tracking
    field :needs_periodic_inspection, :boolean, default: false
    field :inspection_interval_days, :integer
    field :last_inspection_date, :date
    field :next_inspection_date, :date
    field :days_to_inspection_alert, :integer

    field :notes, :string
    field :is_deleted, :boolean, default: false
    field :deleted_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  Default scope - returns only active (non-deleted) resources
  """
  def active(query \\ __MODULE__) do
    from r in query, where: r.is_deleted == false
  end

  @doc """
  Include deleted resources
  """
  def with_deleted(query \\ __MODULE__) do
    query
  end

  @doc """
  Filter by category
  """
  def by_category(query \\ __MODULE__, category) when category in @valid_categories do
    from r in query, where: r.resource_category == ^category
  end

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [
      :name,
      :description,
      :resource_category,
      :default_unit_of_measure,
      :default_unit_cost,
      :needs_periodic_inspection,
      :inspection_interval_days,
      :last_inspection_date,
      :next_inspection_date,
      :days_to_inspection_alert,
      :notes
    ])
    |> validate_required([:name, :resource_category])
    |> validate_inclusion(:resource_category, @valid_categories)
    |> validate_number(:default_unit_cost, greater_than_or_equal_to: 0)
    |> validate_inspection_interval()
  end

  defp validate_inspection_interval(changeset) do
    needs_inspection = get_field(changeset, :needs_periodic_inspection)
    interval = get_field(changeset, :inspection_interval_days)

    if needs_inspection && is_nil(interval) do
      add_error(changeset, :inspection_interval_days, "is required when periodic inspection is enabled")
    else
      changeset
    end
  end

  @doc """
  Changeset for soft delete
  """
  def soft_delete_changeset(resource) do
    resource
    |> change(%{
      is_deleted: true,
      deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  @doc """
  Changeset for restore
  """
  def restore_changeset(resource) do
    resource
    |> change(%{
      is_deleted: false,
      deleted_at: nil
    })
  end
end
