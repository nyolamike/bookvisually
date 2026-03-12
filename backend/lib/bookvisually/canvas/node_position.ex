defmodule BookVisually.Canvas.NodePosition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "node_positions" do
    belongs_to :canvas_state, BookVisually.Canvas.State

    field :node_type, :string
    field :entity_id, :string  # Changed from :integer to :string for UUID support
    field :position, :map
    field :dimensions, :map
    field :ui_metadata, :map
    field :z_index, :integer, default: 0

    timestamps()
  end

  @entity_types ["account", "resource", "expense", "bill", "supply"]

  @doc false
  def changeset(node_position, attrs) do
    node_position
    |> cast(attrs, [:canvas_state_id, :node_type, :entity_id, :position, :dimensions, :ui_metadata, :z_index])
    |> validate_required([:canvas_state_id, :node_type, :position])
    |> validate_node_type()
    |> foreign_key_constraint(:canvas_state_id)
  end

  defp validate_node_type(changeset) do
    node_type = get_field(changeset, :node_type)
    entity_id = get_field(changeset, :entity_id)

    if node_type in @entity_types and is_nil(entity_id) do
      add_error(changeset, :entity_id, "required for #{node_type} nodes")
    else
      changeset
    end
  end

  @doc """
  Returns true if the node is backed by a database entity.
  """
  def entity_node?(%__MODULE__{node_type: type}) do
    type in @entity_types
  end

  @doc """
  Returns true if the node is a UI widget (not backed by an entity).
  """
  def widget_node?(%__MODULE__{} = node) do
    not entity_node?(node)
  end
end
