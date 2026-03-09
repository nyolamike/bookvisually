defmodule BookVisuallyWeb.ResourceController do
  use BookVisuallyWeb, :controller

  alias BookVisually.Resources
  alias BookVisually.Resources.Resource

  action_fallback BookVisuallyWeb.FallbackController

  def index(conn, %{"category" => category}) do
    resources = Resources.list_resources_by_category(category)
    render(conn, :index, resources: resources)
  end

  def index(conn, _params) do
    resources = Resources.list_resources()
    render(conn, :index, resources: resources)
  end

  def create(conn, %{"resource" => resource_params}) do
    case resource_params["resource_category"] do
      "supply" ->
        with {:ok, %Resource{} = resource} <- Resources.create_supply_resource(resource_params) do
          conn
          |> put_status(:created)
          |> put_resp_header("location", ~p"/api/resources/#{resource}")
          |> render(:show, resource: resource)
        end

      "asset" ->
        with {:ok, %Resource{} = resource} <- Resources.create_asset_resource(resource_params) do
          conn
          |> put_status(:created)
          |> put_resp_header("location", ~p"/api/resources/#{resource}")
          |> render(:show, resource: resource)
        end

      "subscription" ->
        with {:ok, %Resource{} = resource} <- Resources.create_subscription_resource(resource_params) do
          conn
          |> put_status(:created)
          |> put_resp_header("location", ~p"/api/resources/#{resource}")
          |> render(:show, resource: resource)
        end

      "utility" ->
        with {:ok, %Resource{} = resource} <- Resources.create_utility_resource(resource_params) do
          conn
          |> put_status(:created)
          |> put_resp_header("location", ~p"/api/resources/#{resource}")
          |> render(:show, resource: resource)
        end

      _ ->
        with {:ok, %Resource{} = resource} <- Resources.create_resource(resource_params) do
          conn
          |> put_status(:created)
          |> put_resp_header("location", ~p"/api/resources/#{resource}")
          |> render(:show, resource: resource)
        end
    end
  end

  def show(conn, %{"id" => id}) do
    resource = Resources.get_resource!(id)
    render(conn, :show, resource: resource)
  end

  def update(conn, %{"id" => id, "resource" => resource_params}) do
    resource = Resources.get_resource!(id)

    with {:ok, %Resource{} = resource} <- Resources.update_resource(resource, resource_params) do
      render(conn, :show, resource: resource)
    end
  end

  def delete(conn, %{"id" => id}) do
    resource = Resources.get_resource!(id)

    with {:ok, %Resource{}} <- Resources.soft_delete_resource(resource) do
      send_resp(conn, :no_content, "")
    end
  end

  def history(conn, %{"resource_id" => id}) do
    resource = Resources.get_resource!(id)
    # This will be implemented when we add history tracking
    render(conn, :history, resource: resource, history: [])
  end
end
