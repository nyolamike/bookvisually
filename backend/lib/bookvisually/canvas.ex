defmodule BookVisually.Canvas do
  @moduledoc """
  The Canvas context for managing canvas states and node positions.
  """

  import Ecto.Query, warn: false
  alias BookVisually.Repo
  alias BookVisually.Canvas.{State, NodePosition, Edge}

  @doc """
  Gets a single canvas state with all node positions preloaded.
  """
  def get_canvas_state(id) do
    State
    |> preload([:node_positions, :edges])
    |> Repo.get(id)
  end

  @doc """
  Gets a canvas state by name.
  """
  def get_canvas_state_by_name(name) do
    State
    |> where([s], s.name == ^name)
    |> preload([:node_positions, :edges])
    |> Repo.one()
  end

  @doc """
  Lists all canvas states.
  """
  def list_canvas_states do
    Repo.all(State)
  end

  @doc """
  Creates a canvas state.
  """
  def create_canvas_state(attrs \\ %{}) do
    %State{}
    |> State.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a canvas state.
  """
  def update_canvas_state(%State{} = state, attrs) do
    state
    |> State.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a canvas state.
  """
  def delete_canvas_state(%State{} = state) do
    Repo.delete(state)
  end

  @doc """
  Creates a node position.
  """
  def create_node_position(attrs \\ %{}) do
    %NodePosition{}
    |> NodePosition.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a node position.
  """
  def update_node_position(%NodePosition{} = node_position, attrs) do
    node_position
    |> NodePosition.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a node position.
  """
  def delete_node_position(%NodePosition{} = node_position) do
    Repo.delete(node_position)
  end

  @doc """
  Creates an edge.
  """
  def create_edge(attrs \\ %{}) do
    %Edge{}
    |> Edge.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an edge.
  """
  def update_edge(%Edge{} = edge, attrs) do
    edge
    |> Edge.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an edge.
  """
  def delete_edge(%Edge{} = edge) do
    Repo.delete(edge)
  end

  @doc """
  Saves the entire canvas state including all nodes.
  Replaces all existing nodes with the provided ones.
  """
  def save_full_canvas_state(name, attrs) do
    Repo.transaction(fn ->
      # Get or create canvas state
      canvas_state = case get_canvas_state_by_name(name) do
        nil ->
          {:ok, state} = create_canvas_state(%{name: name, viewport: attrs[:viewport] || %{}})
          state
        existing ->
          {:ok, state} = update_canvas_state(existing, %{viewport: attrs[:viewport] || %{}})
          state
      end

      # Delete existing nodes and edges
      from(n in NodePosition, where: n.canvas_state_id == ^canvas_state.id)
      |> Repo.delete_all()
      
      from(e in Edge, where: e.canvas_state_id == ^canvas_state.id)
      |> Repo.delete_all()

      # Insert new nodes
      nodes = attrs[:nodes] || []
      Enum.each(nodes, fn node_attrs ->
        # Convert string keys to atoms and add canvas_state_id
        node_params = %{
          canvas_state_id: canvas_state.id,
          node_type: node_attrs["node_type"] || node_attrs[:node_type],
          entity_id: node_attrs["entity_id"] || node_attrs[:entity_id],
          position: node_attrs["position"] || node_attrs[:position],
          dimensions: node_attrs["dimensions"] || node_attrs[:dimensions],
          ui_metadata: node_attrs["ui_metadata"] || node_attrs[:ui_metadata] || %{},
          z_index: node_attrs["z_index"] || node_attrs[:z_index] || 0
        }
        
        case create_node_position(node_params) do
          {:ok, _node} -> :ok
          {:error, changeset} -> 
            IO.inspect(changeset, label: "Failed to create node")
            :error
        end
      end)

      # Insert new edges
      edges = attrs[:edges] || []
      IO.inspect(edges, label: "Edges to insert")
      
      Enum.each(edges, fn edge_attrs ->
        # Convert string keys to atoms and add canvas_state_id
        edge_params = %{
          canvas_state_id: canvas_state.id,
          source_node_type: edge_attrs["source_node_type"] || edge_attrs[:source_node_type],
          source_entity_id: edge_attrs["source_entity_id"] || edge_attrs[:source_entity_id],
          target_node_type: edge_attrs["target_node_type"] || edge_attrs[:target_node_type],
          target_entity_id: edge_attrs["target_entity_id"] || edge_attrs[:target_entity_id],
          edge_metadata: edge_attrs["edge_metadata"] || edge_attrs[:edge_metadata] || %{}
        }
        
        IO.inspect(edge_params, label: "Edge params")
        
        case create_edge(edge_params) do
          {:ok, edge} -> 
            IO.inspect(edge, label: "Edge created successfully")
            :ok
          {:error, changeset} -> 
            IO.inspect(changeset, label: "Failed to create edge")
            :error
        end
      end)

      # Return the updated state with nodes and edges
      get_canvas_state(canvas_state.id)
    end)
  end

  @doc """
  Updates only the positions of existing nodes without replacing all nodes.
  """
  def update_node_positions(canvas_state_id, node_updates) do
    Repo.transaction(fn ->
      Enum.each(node_updates, fn update ->
        query = from n in NodePosition,
          where: n.canvas_state_id == ^canvas_state_id and
                 n.node_type == ^update.node_type

        query = if update[:entity_id] do
          from n in query, where: n.entity_id == ^update.entity_id
        else
          from n in query, where: is_nil(n.entity_id)
        end

        case Repo.one(query) do
          nil -> :ok
          node -> update_node_position(node, update)
        end
      end)

      get_canvas_state(canvas_state_id)
    end)
  end
end
