defmodule BookVisually.Canvas.Edge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "canvas_edges" do
    belongs_to :canvas_state, BookVisually.Canvas.State

    field :source_node_type, :string
    field :source_entity_id, :string  # Changed from :integer to :string for UUID support
    field :target_node_type, :string
    field :target_entity_id, :string  # Changed from :integer to :string for UUID support
    field :edge_metadata, :map

    timestamps()
  end

  @doc false
  def changeset(edge, attrs) do
    edge
    |> cast(attrs, [:canvas_state_id, :source_node_type, :source_entity_id, :target_node_type, :target_entity_id, :edge_metadata])
    |> validate_required([:canvas_state_id, :source_node_type, :target_node_type])
    |> foreign_key_constraint(:canvas_state_id)
  end
end
