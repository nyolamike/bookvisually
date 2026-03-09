defmodule BookVisuallyWeb.SupplyController do
  use BookVisuallyWeb, :controller

  alias BookVisually.Supplies
  alias BookVisually.Supplies.SupplyStockMovement

  action_fallback BookVisuallyWeb.FallbackController

  def purchase(conn, %{"id" => resource_id} = params) do
    movement_params = %{
      supply_resource_id: resource_id,
      movement_type: "purchase",
      quantity_change: params["quantity"],
      movement_date: params["movement_date"] || Date.utc_today(),
      expense_id: params["expense_id"],
      description: params["description"]
    }

    with {:ok, %SupplyStockMovement{} = movement} <- Supplies.create_stock_movement(movement_params) do
      conn
      |> put_status(:created)
      |> render(:show, movement: movement)
    end
  end

  def usage(conn, %{"id" => resource_id} = params) do
    movement_params = %{
      supply_resource_id: resource_id,
      movement_type: "usage",
      quantity_change: params["quantity"],
      movement_date: params["movement_date"] || Date.utc_today(),
      used_by: params["used_by"],
      description: params["description"]
    }

    with {:ok, %SupplyStockMovement{} = movement} <- Supplies.create_stock_movement(movement_params) do
      conn
      |> put_status(:created)
      |> render(:show, movement: movement)
    end
  end

  def adjustment(conn, %{"id" => resource_id} = params) do
    movement_params = %{
      supply_resource_id: resource_id,
      movement_type: "adjustment",
      quantity_change: params["quantity_change"],
      movement_date: params["movement_date"] || Date.utc_today(),
      description: params["description"] || "Stock adjustment"
    }

    with {:ok, %SupplyStockMovement{} = movement} <- Supplies.create_stock_movement(movement_params) do
      conn
      |> put_status(:created)
      |> render(:show, movement: movement)
    end
  end

  def disposal(conn, %{"id" => resource_id} = params) do
    movement_params = %{
      supply_resource_id: resource_id,
      movement_type: "disposal",
      quantity_change: params["quantity"],
      movement_date: params["movement_date"] || Date.utc_today(),
      description: params["description"]
    }

    with {:ok, %SupplyStockMovement{} = movement} <- Supplies.create_stock_movement(movement_params) do
      conn
      |> put_status(:created)
      |> render(:show, movement: movement)
    end
  end

  def return(conn, %{"id" => resource_id} = params) do
    movement_params = %{
      supply_resource_id: resource_id,
      movement_type: "return",
      quantity_change: params["quantity"],
      movement_date: params["movement_date"] || Date.utc_today(),
      description: params["description"]
    }

    with {:ok, %SupplyStockMovement{} = movement} <- Supplies.create_stock_movement(movement_params) do
      conn
      |> put_status(:created)
      |> render(:show, movement: movement)
    end
  end

  def movements(conn, %{"id" => resource_id}) do
    movements = Supplies.list_movements_for_supply(resource_id)
    resource = BookVisually.Resources.get_resource!(resource_id)

    render(conn, :movements, resource: resource, movements: movements)
  end
end
