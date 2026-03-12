defmodule Bookvisually.Repo.Migrations.ChangeEntityIdToUuid do
  use Ecto.Migration

  def change do
    # Change entity_id in node_positions to string (UUID)
    alter table(:node_positions) do
      modify :entity_id, :string
    end

    # Change entity_id in canvas_edges to string (UUID)
    alter table(:canvas_edges) do
      modify :source_entity_id, :string
      modify :target_entity_id, :string
    end
  end
end
