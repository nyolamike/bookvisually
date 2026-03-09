defmodule BookVisually.SuppliesTest do
  use BookVisually.DataCase

  alias BookVisually.Supplies
  alias BookVisually.Resources

  describe "supply_stock_movements" do
    setup do
      {:ok, resource} = Resources.create_supply_resource(%{
        name: "Generator Fuel",
        resource_category: "supply",
        default_unit_of_measure: "liters",
        supply_properties: %{
          out_of_stock_alert_quantity: Decimal.new("10"),
          current_stock_quantity: Decimal.new("50")
        }
      })

      %{resource: resource}
    end

    test "list_movements/0 returns all movements", %{resource: resource} do
      {:ok, _movement} = Supplies.record_purchase(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("100")
      })

      movements = Supplies.list_movements()
      assert length(movements) == 1
    end

    test "list_movements_by_resource/1 filters by resource", %{resource: resource} do
      {:ok, other_resource} = Resources.create_supply_resource(%{
        name: "Wood Varnish",
        resource_category: "supply",
        supply_properties: %{}
      })

      {:ok, _m1} = Supplies.record_purchase(%{resource_id: resource.id, quantity_change: Decimal.new("100")})
      {:ok, _m2} = Supplies.record_purchase(%{resource_id: other_resource.id, quantity_change: Decimal.new("50")})

      movements = Supplies.list_movements_by_resource(resource.id)
      assert length(movements) == 1
    end

    test "list_movements_by_type/1 filters by movement type", %{resource: resource} do
      {:ok, _purchase} = Supplies.record_purchase(%{resource_id: resource.id, quantity_change: Decimal.new("100")})
      {:ok, _usage} = Supplies.record_usage(%{resource_id: resource.id, quantity_change: Decimal.new("20")})

      purchases = Supplies.list_movements_by_type("purchase")
      usages = Supplies.list_movements_by_type("usage")

      assert length(purchases) == 1
      assert length(usages) == 1
    end

    test "list_movements_by_date_range/2 filters by date", %{resource: resource} do
      {:ok, _m1} = Supplies.record_purchase(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("100"),
        movement_date: ~U[2026-03-01 10:00:00Z]
      })
      {:ok, _m2} = Supplies.record_purchase(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("50"),
        movement_date: ~U[2026-03-15 10:00:00Z]
      })

      movements = Supplies.list_movements_by_date_range(~D[2026-03-10], ~D[2026-03-20])
      assert length(movements) == 1
    end

    test "record_purchase/1 creates movement and increases stock", %{resource: resource} do
      initial_stock = resource.supply_properties.current_stock_quantity

      assert {:ok, movement} = Supplies.record_purchase(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("100"),
        unit_of_measure: "liters",
        description: "Fuel purchase"
      })

      assert movement.movement_type == "purchase"
      assert Decimal.equal?(movement.quantity_change, Decimal.new("100"))
      assert Decimal.equal?(movement.stock_after_movement, Decimal.add(initial_stock, Decimal.new("100")))

      updated_properties = Resources.get_supply_properties!(resource.id)
      assert Decimal.equal?(updated_properties.current_stock_quantity, Decimal.add(initial_stock, Decimal.new("100")))
    end

    test "record_usage/1 creates movement and decreases stock", %{resource: resource} do
      initial_stock = resource.supply_properties.current_stock_quantity

      assert {:ok, movement} = Supplies.record_usage(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("20"),
        used_by: "John the Carpenter",
        description: "Generator run - 4 hours"
      })

      assert movement.movement_type == "usage"
      assert Decimal.equal?(movement.quantity_change, Decimal.new("-20"))
      assert Decimal.equal?(movement.stock_after_movement, Decimal.sub(initial_stock, Decimal.new("20")))
      assert movement.used_by == "John the Carpenter"

      updated_properties = Resources.get_supply_properties!(resource.id)
      assert Decimal.equal?(updated_properties.current_stock_quantity, Decimal.sub(initial_stock, Decimal.new("20")))
    end

    test "record_usage/1 fails when insufficient stock", %{resource: resource} do
      assert {:error, _reason} = Supplies.record_usage(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("100")
      })

      # Verify stock unchanged
      updated_properties = Resources.get_supply_properties!(resource.id)
      assert Decimal.equal?(updated_properties.current_stock_quantity, Decimal.new("50"))
    end

    test "record_usage/1 handles negative quantity input", %{resource: resource} do
      # Should work even if user provides negative quantity
      assert {:ok, movement} = Supplies.record_usage(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("-20")
      })

      assert Decimal.equal?(movement.quantity_change, Decimal.new("-20"))
    end

    test "record_adjustment/1 with positive adjustment increases stock", %{resource: resource} do
      initial_stock = resource.supply_properties.current_stock_quantity

      assert {:ok, movement} = Supplies.record_adjustment(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("10"),
        description: "Stock count correction"
      })

      assert movement.movement_type == "adjustment"
      assert Decimal.equal?(movement.quantity_change, Decimal.new("10"))

      updated_properties = Resources.get_supply_properties!(resource.id)
      assert Decimal.equal?(updated_properties.current_stock_quantity, Decimal.add(initial_stock, Decimal.new("10")))
    end

    test "record_adjustment/1 with negative adjustment decreases stock", %{resource: resource} do
      initial_stock = resource.supply_properties.current_stock_quantity

      assert {:ok, movement} = Supplies.record_adjustment(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("-10"),
        description: "Stock count correction"
      })

      assert movement.movement_type == "adjustment"
      assert Decimal.equal?(movement.quantity_change, Decimal.new("-10"))

      updated_properties = Resources.get_supply_properties!(resource.id)
      assert Decimal.equal?(updated_properties.current_stock_quantity, Decimal.sub(initial_stock, Decimal.new("10")))
    end

    test "record_adjustment/1 fails when would result in negative stock", %{resource: resource} do
      assert {:error, _reason} = Supplies.record_adjustment(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("-100")
      })

      # Verify stock unchanged
      updated_properties = Resources.get_supply_properties!(resource.id)
      assert Decimal.equal?(updated_properties.current_stock_quantity, Decimal.new("50"))
    end

    test "record_disposal/1 creates movement and decreases stock", %{resource: resource} do
      initial_stock = resource.supply_properties.current_stock_quantity

      assert {:ok, movement} = Supplies.record_disposal(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("15"),
        description: "Expired fuel disposal"
      })

      assert movement.movement_type == "disposal"
      assert Decimal.equal?(movement.quantity_change, Decimal.new("-15"))

      updated_properties = Resources.get_supply_properties!(resource.id)
      assert Decimal.equal?(updated_properties.current_stock_quantity, Decimal.sub(initial_stock, Decimal.new("15")))
    end

    test "record_disposal/1 fails when insufficient stock", %{resource: resource} do
      assert {:error, _reason} = Supplies.record_disposal(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("100")
      })
    end

    test "record_return/1 creates movement and increases stock", %{resource: resource} do
      initial_stock = resource.supply_properties.current_stock_quantity

      assert {:ok, movement} = Supplies.record_return(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("25"),
        description: "Returned unused fuel"
      })

      assert movement.movement_type == "return"
      assert Decimal.equal?(movement.quantity_change, Decimal.new("25"))

      updated_properties = Resources.get_supply_properties!(resource.id)
      assert Decimal.equal?(updated_properties.current_stock_quantity, Decimal.add(initial_stock, Decimal.new("25")))
    end

    test "movements can be linked to expenses", %{resource: resource} do
      {:ok, expense} = BookVisually.Expenses.create_expense(%{
        resource_id: resource.id,
        expense_date: ~D[2026-03-08],
        total_amount: Decimal.new("200")
      })

      assert {:ok, movement} = Supplies.record_purchase(%{
        resource_id: resource.id,
        expense_id: expense.id,
        quantity_change: Decimal.new("100")
      })

      assert movement.expense_id == expense.id
    end

    test "get_total_usage_for_resource/1 returns sum of usage", %{resource: resource} do
      {:ok, _} = Supplies.record_usage(%{resource_id: resource.id, quantity_change: Decimal.new("10")})
      {:ok, _} = Supplies.record_usage(%{resource_id: resource.id, quantity_change: Decimal.new("15")})
      {:ok, _} = Supplies.record_purchase(%{resource_id: resource.id, quantity_change: Decimal.new("50")})

      total_usage = Supplies.get_total_usage_for_resource(resource.id)
      assert Decimal.equal?(total_usage, Decimal.new("25"))
    end

    test "movements automatically set movement_date if not provided", %{resource: resource} do
      {:ok, movement} = Supplies.record_purchase(%{
        resource_id: resource.id,
        quantity_change: Decimal.new("100")
      })

      assert movement.movement_date != nil
    end

    test "movements update supply status based on stock level", %{resource: resource} do
      # Use stock down to low level
      {:ok, _} = Supplies.record_usage(%{resource_id: resource.id, quantity_change: Decimal.new("45")})

      properties = Resources.get_supply_properties!(resource.id)
      assert properties.status == "low_stock"

      # Use remaining stock
      {:ok, _} = Supplies.record_usage(%{resource_id: resource.id, quantity_change: Decimal.new("5")})

      properties = Resources.get_supply_properties!(resource.id)
      assert properties.status == "out_of_stock"

      # Restock
      {:ok, _} = Supplies.record_purchase(%{resource_id: resource.id, quantity_change: Decimal.new("100")})

      properties = Resources.get_supply_properties!(resource.id)
      assert properties.status == "in_stock"
    end

    test "movements rollback on stock update failure" do
      # Create resource with no supply properties (will fail when trying to update stock)
      {:ok, resource} = Resources.create_resource(%{
        name: "Invalid Supply",
        resource_category: "supply"
      })

      # This should fail because there are no supply properties
      assert_raise Ecto.NoResultsError, fn ->
        Supplies.record_purchase(%{
          resource_id: resource.id,
          quantity_change: Decimal.new("100")
        })
      end

      # Verify no movement was created (transaction rolled back)
      movements = Supplies.list_movements_by_resource(resource.id)
      assert movements == []
    end
  end
end
