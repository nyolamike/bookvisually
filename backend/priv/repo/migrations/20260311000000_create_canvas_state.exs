defmodule Bookvisually.Repo.Migrations.CreateCanvasState do
  use Ecto.Migration

  def change do
    create table(:canvas_states) do
      add :name, :string, null: false
      add :viewport, :map, default: %{}

      timestamps()
    end

    create table(:node_positions) do
      add :canvas_state_id, references(:canvas_states, on_delete: :delete_all), null: false
      add :node_type, :string, null: false
      add :entity_id, :integer
      add :position, :map, null: false
      add :dimensions, :map
      add :ui_metadata, :map, default: %{}
      add :z_index, :integer, default: 0

      timestamps()
    end

    create index(:node_positions, [:canvas_state_id])
    create index(:node_positions, [:node_type, :entity_id])
  end
end
