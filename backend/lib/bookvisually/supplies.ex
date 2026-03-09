defmodule BookVisually.Supplies do
  @moduledoc """
  The Supplies context.
  Handles all business logic for managing supply stock movements.
  """

  import Ecto.Query, warn: false
  alias BookVisually.Repo
  alias BookVisually.Supplies.SupplyStockMovement
  alias BookVisually.Resources

  @doc """
  Returns the list of stock movements.
  """
  def list_movements do
    SupplyStockMovement
    |> SupplyStockMovement.order_by_date_desc()
    |> Repo.all()
  end

  @doc """
  Returns movements for a specific resource.
  """
  def list_movements_by_resource(resource_id) do
    SupplyStockMovement
    |> SupplyStockMovement.by_resource(resource_id)
    |> SupplyStockMovement.order_by_date_desc()
    |> Repo.all()
  end

  @doc """
  Returns movements for a specific supply.
  Alias for list_movements_by_resource/1.
  """
  def list_movements_for_supply(resource_id), do: list_movements_by_resource(resource_id)

  @doc """
  Creates a stock movement with automatic stock updates.
  This is a generic function that handles all movement types.
  """
  def create_stock_movement(attrs) do
    movement_type = attrs[:movement_type] || attrs["movement_type"]

    case movement_type do
      "purchase" -> record_purchase(Map.put(attrs, :resource_id, attrs[:supply_resource_id] || attrs["supply_resource_id"]))
      "usage" -> record_usage(Map.put(attrs, :resource_id, attrs[:supply_resource_id] || attrs["supply_resource_id"]))
      "adjustment" -> record_adjustment(Map.put(attrs, :resource_id, attrs[:supply_resource_id] || attrs["supply_resource_id"]))
      "disposal" -> record_disposal(Map.put(attrs, :resource_id, attrs[:supply_resource_id] || attrs["supply_resource_id"]))
      "return" -> record_return(Map.put(attrs, :resource_id, attrs[:supply_resource_id] || attrs["supply_resource_id"]))
      _ -> {:error, :invalid_movement_type}
    end
  end

  @doc """
  Returns movements by type.
  """
  def list_movements_by_type(movement_type) do
    SupplyStockMovement
    |> SupplyStockMovement.by_type(movement_type)
    |> SupplyStockMovement.order_by_date_desc()
    |> Repo.all()
  end

  @doc """
  Returns movements within a date range.
  """
  def list_movements_by_date_range(start_date, end_date) do
    SupplyStockMovement
    |> SupplyStockMovement.by_date_range(start_date, end_date)
    |> SupplyStockMovement.order_by_date_desc()
    |> Repo.all()
  end

  @doc """
  Gets a single movement.
  """
  def get_movement!(id) do
    Repo.get!(SupplyStockMovement, id)
  end

  @doc """
  Records a purchase movement and updates stock.
  Links to an expense if provided.
  """
  def record_purchase(attrs) do
    Repo.transaction(fn ->
      resource_id = attrs[:resource_id] || attrs["resource_id"]
      quantity = attrs[:quantity_change] || attrs["quantity_change"]

      properties = Resources.get_supply_properties!(resource_id)
      new_stock = Decimal.add(properties.current_stock_quantity, quantity)

      movement_attrs = attrs
      |> Map.put(:movement_type, "purchase")
      |> Map.put(:stock_after_movement, new_stock)

      with {:ok, movement} <- create_movement(movement_attrs),
           {:ok, _properties} <- Resources.update_stock_quantity(properties, new_stock) do
        movement
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Records a usage movement and updates stock.
  """
  def record_usage(attrs) do
    Repo.transaction(fn ->
      resource_id = attrs[:resource_id] || attrs["resource_id"]
      quantity = attrs[:quantity_change] || attrs["quantity_change"]

      # Usage should be negative
      quantity_change = if Decimal.positive?(quantity), do: Decimal.negate(quantity), else: quantity

      properties = Resources.get_supply_properties!(resource_id)
      new_stock = Decimal.add(properties.current_stock_quantity, quantity_change)

      if Decimal.negative?(new_stock) do
        Repo.rollback({:error, "insufficient stock"})
      else
        movement_attrs = attrs
        |> Map.put(:movement_type, "usage")
        |> Map.put(:quantity_change, quantity_change)
        |> Map.put(:stock_after_movement, new_stock)

        with {:ok, movement} <- create_movement(movement_attrs),
             {:ok, _properties} <- Resources.update_stock_quantity(properties, new_stock) do
          movement
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end
    end)
  end

  @doc """
  Records an adjustment movement and updates stock.
  Can be positive or negative.
  """
  def record_adjustment(attrs) do
    Repo.transaction(fn ->
      resource_id = attrs[:resource_id] || attrs["resource_id"]
      quantity = attrs[:quantity_change] || attrs["quantity_change"]

      properties = Resources.get_supply_properties!(resource_id)
      new_stock = Decimal.add(properties.current_stock_quantity, quantity)

      if Decimal.negative?(new_stock) do
        Repo.rollback({:error, "adjustment would result in negative stock"})
      else
        movement_attrs = attrs
        |> Map.put(:movement_type, "adjustment")
        |> Map.put(:stock_after_movement, new_stock)

        with {:ok, movement} <- create_movement(movement_attrs),
             {:ok, _properties} <- Resources.update_stock_quantity(properties, new_stock) do
          movement
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end
    end)
  end

  @doc """
  Records a disposal movement and updates stock.
  """
  def record_disposal(attrs) do
    Repo.transaction(fn ->
      resource_id = attrs[:resource_id] || attrs["resource_id"]
      quantity = attrs[:quantity_change] || attrs["quantity_change"]

      # Disposal should be negative
      quantity_change = if Decimal.positive?(quantity), do: Decimal.negate(quantity), else: quantity

      properties = Resources.get_supply_properties!(resource_id)
      new_stock = Decimal.add(properties.current_stock_quantity, quantity_change)

      if Decimal.negative?(new_stock) do
        Repo.rollback({:error, "insufficient stock for disposal"})
      else
        movement_attrs = attrs
        |> Map.put(:movement_type, "disposal")
        |> Map.put(:quantity_change, quantity_change)
        |> Map.put(:stock_after_movement, new_stock)

        with {:ok, movement} <- create_movement(movement_attrs),
             {:ok, _properties} <- Resources.update_stock_quantity(properties, new_stock) do
          movement
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end
    end)
  end

  @doc """
  Records a return movement and updates stock.
  """
  def record_return(attrs) do
    Repo.transaction(fn ->
      resource_id = attrs[:resource_id] || attrs["resource_id"]
      quantity = attrs[:quantity_change] || attrs["quantity_change"]

      properties = Resources.get_supply_properties!(resource_id)
      new_stock = Decimal.add(properties.current_stock_quantity, quantity)

      movement_attrs = attrs
      |> Map.put(:movement_type, "return")
      |> Map.put(:stock_after_movement, new_stock)

      with {:ok, movement} <- create_movement(movement_attrs),
           {:ok, _properties} <- Resources.update_stock_quantity(properties, new_stock) do
        movement
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Gets total quantity used for a resource.
  """
  def get_total_usage_for_resource(resource_id) do
    SupplyStockMovement
    |> SupplyStockMovement.by_resource(resource_id)
    |> SupplyStockMovement.by_type("usage")
    |> select([m], sum(m.quantity_change))
    |> Repo.one()
    |> case do
      nil -> Decimal.new("0")
      total -> Decimal.abs(total)
    end
  end

  # Private helper functions

  defp create_movement(attrs) do
    %SupplyStockMovement{}
    |> SupplyStockMovement.changeset(attrs)
    |> Repo.insert()
  end
end
