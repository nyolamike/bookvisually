defmodule BookVisuallyWeb.SupplyJSON do
  alias BookVisually.Supplies.SupplyStockMovement

  @doc """
  Renders a single stock movement.
  """
  def show(%{movement: movement}) do
    %{data: data(movement)}
  end

  @doc """
  Renders stock movements with resource info.
  """
  def movements(%{resource: resource, movements: movements}) do
    %{
      data: %{
        resource: %{
          id: resource.id,
          name: resource.name,
          current_stock: get_current_stock(resource)
        },
        movements: for(movement <- movements, do: data(movement))
      }
    }
  end

  defp data(%SupplyStockMovement{} = movement) do
    %{
      id: movement.id,
      resource_id: movement.resource_id,
      movement_type: movement.movement_type,
      quantity_change: movement.quantity_change,
      stock_after_movement: movement.stock_after_movement,
      movement_date: movement.movement_date,
      expense_id: movement.expense_id,
      used_by: movement.used_by,
      description: movement.description,
      inserted_at: movement.inserted_at
    }
  end

  defp get_current_stock(resource) do
    case resource.supply_properties do
      %Ecto.Association.NotLoaded{} -> nil
      nil -> nil
      props -> props.current_stock_quantity
    end
  end
end
