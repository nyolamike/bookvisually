defmodule BookVisually.SupplyResourcePropertiesTest do
  use BookVisually.DataCase

  alias BookVisually.Resources
  alias BookVisually.Resources.SupplyResourceProperties

  describe "supply_resource_properties" do
    setup do
      {:ok, resource} = Resources.create_resource(%{
        name: "Wood Varnish",
        resource_category: "supply",
        default_unit_of_measure: "liters"
      })

      %{resource: resource}
    end

    @valid_attrs %{
      issues_out_of_stock_alerts: true,
      out_of_stock_alert_quantity: Decimal.new("10"),
      current_stock_quantity: Decimal.new("50"),
      status: "in_stock"
    }

    @invalid_attrs %{
      resource_id: nil
    }

    test "create_supply_properties/1 with valid data creates properties", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)

      assert {:ok, %SupplyResourceProperties{} = properties} = Resources.create_supply_properties(attrs)
      assert properties.resource_id == resource.id
      assert properties.issues_out_of_stock_alerts == true
      assert Decimal.equal?(properties.out_of_stock_alert_quantity, Decimal.new("10"))
      assert Decimal.equal?(properties.current_stock_quantity, Decimal.new("50"))
      assert properties.status == "in_stock"
    end

    test "create_supply_properties/1 with invalid data returns error" do
      assert {:error, %Ecto.Changeset{}} = Resources.create_supply_properties(@invalid_attrs)
    end

    test "create_supply_properties/1 with invalid status returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:status, "invalid_status")

      assert {:error, changeset} = Resources.create_supply_properties(attrs)
      assert "is invalid" in errors_on(changeset).status
    end

    test "create_supply_properties/1 with negative stock returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:current_stock_quantity, Decimal.new("-5"))

      assert {:error, changeset} = Resources.create_supply_properties(attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).current_stock_quantity
    end

    test "get_supply_properties!/1 returns properties", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_supply_properties(attrs)

      fetched = Resources.get_supply_properties!(resource.id)
      assert fetched.resource_id == properties.resource_id
    end

    test "update_supply_properties/2 with valid data updates properties", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_supply_properties(attrs)

      update_attrs = %{out_of_stock_alert_quantity: Decimal.new("5")}
      assert {:ok, updated} = Resources.update_supply_properties(properties, update_attrs)
      assert Decimal.equal?(updated.out_of_stock_alert_quantity, Decimal.new("5"))
    end

    test "update_stock_quantity/2 updates quantity and status to in_stock", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:current_stock_quantity, Decimal.new("0"))
      |> Map.put(:status, "out_of_stock")

      {:ok, properties} = Resources.create_supply_properties(attrs)

      assert {:ok, updated} = Resources.update_stock_quantity(properties, Decimal.new("50"))
      assert Decimal.equal?(updated.current_stock_quantity, Decimal.new("50"))
      assert updated.status == "in_stock"
    end

    test "update_stock_quantity/2 sets status to low_stock when below threshold", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:out_of_stock_alert_quantity, Decimal.new("10"))

      {:ok, properties} = Resources.create_supply_properties(attrs)

      assert {:ok, updated} = Resources.update_stock_quantity(properties, Decimal.new("5"))
      assert Decimal.equal?(updated.current_stock_quantity, Decimal.new("5"))
      assert updated.status == "low_stock"
    end

    test "update_stock_quantity/2 sets status to out_of_stock when zero", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_supply_properties(attrs)

      assert {:ok, updated} = Resources.update_stock_quantity(properties, Decimal.new("0"))
      assert Decimal.equal?(updated.current_stock_quantity, Decimal.new("0"))
      assert updated.status == "out_of_stock"
    end

    test "create_supply_resource/1 creates resource and properties together" do
      attrs = %{
        name: "Generator Fuel",
        resource_category: "supply",
        default_unit_of_measure: "liters",
        supply_properties: %{
          issues_out_of_stock_alerts: true,
          out_of_stock_alert_quantity: Decimal.new("20"),
          current_stock_quantity: Decimal.new("100")
        }
      }

      assert {:ok, resource} = Resources.create_supply_resource(attrs)
      assert resource.name == "Generator Fuel"
      assert resource.supply_properties != nil
      assert resource.supply_properties.issues_out_of_stock_alerts == true
      assert Decimal.equal?(resource.supply_properties.out_of_stock_alert_quantity, Decimal.new("20"))
    end

    test "create_supply_resource/1 rolls back on invalid properties" do
      attrs = %{
        name: "Invalid Supply",
        resource_category: "supply",
        supply_properties: %{
          current_stock_quantity: Decimal.new("-10")  # Invalid
        }
      }

      # Count resources before
      count_before = length(Resources.list_resources())

      assert {:error, _changeset} = Resources.create_supply_resource(attrs)
      
      # Verify resource count didn't change
      count_after = length(Resources.list_resources())
      assert count_after == count_before
    end
  end
end
