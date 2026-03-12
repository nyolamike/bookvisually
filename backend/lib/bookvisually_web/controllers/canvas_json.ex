defmodule BookVisuallyWeb.CanvasJSON do
  alias BookVisually.Canvas.State
  alias BookVisually.Canvas.NodePosition
  alias BookVisually.Canvas.Edge

  @doc """
  Renders a list of canvas states.
  """
  def index(%{canvas_states: canvas_states}) do
    %{data: for(canvas_state <- canvas_states, do: data(canvas_state))}
  end

  @doc """
  Renders a single canvas state with nodes.
  """
  def show(%{canvas_state: canvas_state}) do
    %{data: data_with_nodes(canvas_state)}
  end

  defp data(%State{} = canvas_state) do
    %{
      id: canvas_state.id,
      name: canvas_state.name,
      viewport: canvas_state.viewport || %{},
      inserted_at: canvas_state.inserted_at,
      updated_at: canvas_state.updated_at
    }
  end

  defp data_with_nodes(%State{} = canvas_state) do
    %{
      id: canvas_state.id,
      name: canvas_state.name,
      viewport: canvas_state.viewport || %{},
      nodes: for(node <- canvas_state.node_positions, do: node_data(node)),
      edges: for(edge <- canvas_state.edges, do: edge_data(edge)),
      inserted_at: canvas_state.inserted_at,
      updated_at: canvas_state.updated_at
    }
  end

  defp node_data(%NodePosition{} = node) do
    %{
      id: node.id,
      node_type: node.node_type,
      entity_id: node.entity_id,
      position: node.position,
      dimensions: node.dimensions,
      ui_metadata: node.ui_metadata || %{},
      z_index: node.z_index
    }
  end

  defp edge_data(%Edge{} = edge) do
    %{
      id: edge.id,
      source_node_type: edge.source_node_type,
      source_entity_id: edge.source_entity_id,
      target_node_type: edge.target_node_type,
      target_entity_id: edge.target_entity_id,
      edge_metadata: edge.edge_metadata || %{}
    }
  end
end
