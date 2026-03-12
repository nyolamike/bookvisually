defmodule BookVisuallyWeb.CanvasController do
  use BookVisuallyWeb, :controller

  alias BookVisually.Canvas

  action_fallback BookVisuallyWeb.FallbackController

  @doc """
  GET /api/canvas/:name
  Load a canvas state by name
  """
  def show(conn, %{"name" => name}) do
    case Canvas.get_canvas_state_by_name(name) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Canvas not found"})

      canvas_state ->
        render(conn, :show, canvas_state: canvas_state)
    end
  end

  @doc """
  GET /api/canvas
  List all canvas states
  """
  def index(conn, _params) do
    canvas_states = Canvas.list_canvas_states()
    render(conn, :index, canvas_states: canvas_states)
  end

  @doc """
  POST /api/canvas
  Save entire canvas state (create or update)
  """
  def create(conn, %{"name" => name} = params) do
    viewport = params["viewport"] || %{}
    nodes = params["nodes"] || []
    edges = params["edges"] || []

    case Canvas.save_full_canvas_state(name, %{viewport: viewport, nodes: nodes, edges: edges}) do
      {:ok, canvas_state} ->
        conn
        |> put_status(:created)
        |> render(:show, canvas_state: canvas_state)

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to save canvas state"})
    end
  end

  @doc """
  PATCH /api/canvas/:id/nodes
  Update node positions only
  """
  def update_nodes(conn, %{"id" => id, "nodes" => nodes}) do
    case Canvas.update_node_positions(id, nodes) do
      {:ok, canvas_state} ->
        render(conn, :show, canvas_state: canvas_state)

      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to update node positions"})
    end
  end

  @doc """
  DELETE /api/canvas/:id
  Delete a canvas state
  """
  def delete(conn, %{"id" => id}) do
    case Canvas.get_canvas_state(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Canvas not found"})

      canvas_state ->
        case Canvas.delete_canvas_state(canvas_state) do
          {:ok, _} ->
            send_resp(conn, :no_content, "")

          {:error, _} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "Failed to delete canvas state"})
        end
    end
  end
end
