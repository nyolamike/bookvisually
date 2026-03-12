defmodule BookVisually.Canvas.State do
  use Ecto.Schema
  import Ecto.Changeset

  schema "canvas_states" do
    field :name, :string
    field :viewport, :map

    has_many :node_positions, BookVisually.Canvas.NodePosition, foreign_key: :canvas_state_id
    has_many :edges, BookVisually.Canvas.Edge, foreign_key: :canvas_state_id

    timestamps()
  end

  @doc false
  def changeset(state, attrs) do
    state
    |> cast(attrs, [:name, :viewport])
    |> validate_required([:name])
  end
end
