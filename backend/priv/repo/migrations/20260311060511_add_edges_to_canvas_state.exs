defmodule Bookvisually.Repo.Migrations.AddEdgesToCanvasState do
  use Ecto.Migration

  def change do
    create table(:canvas_edges) do
      add :canvas_state_id, references(:canvas_states, on_delete: :delete_all), null: false
      add :source_node_type, :string, null: false
      add :source_entity_id, :integer
      add :target_node_type, :string, null: false
      add :target_entity_id, :integer
      add :edge_metadata, :map, default: %{}

      timestamps()
    end

    create index(:canvas_edges, [:canvas_state_id])
  end
end
