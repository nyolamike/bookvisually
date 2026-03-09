defmodule BookVisually.AssetResourcePropertiesTest do
  use BookVisually.DataCase

  alias BookVisually.Resources
  alias BookVisually.Resources.AssetResourceProperties

  describe "asset_resource_properties" do
    setup do
      {:ok, resource} = Resources.create_resource(%{
        name: "Office Laptop",
        resource_category: "asset",
        default_unit_of_measure: "units"
      })

      %{resource: resource}
    end

    @valid_attrs %{
      purchase_date: ~D[2024-01-15],
      purchase_cost: Decimal.new("1500.00"),
      depreciation_method: "straight_line",
      depreciation_rate: Decimal.new("20.00"),
      current_value: Decimal.new("1500.00"),
      has_warranty: true,
      warranty_expiry_date: ~D[2025-01-15],
      warranty_status: "active",
      has_guarantee: false,
      guarantee_status: "na",
      status: "okay"
    }

    @invalid_attrs %{
      resource_id: nil,
      purchase_date: nil,
      purchase_cost: nil
    }

    test "create_asset_properties/1 with valid data creates properties", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)

      assert {:ok, %AssetResourceProperties{} = properties} = Resources.create_asset_properties(attrs)
      assert properties.resource_id == resource.id
      assert properties.purchase_date == ~D[2024-01-15]
      assert Decimal.equal?(properties.purchase_cost, Decimal.new("1500.00"))
      assert properties.depreciation_method == "straight_line"
      assert Decimal.equal?(properties.depreciation_rate, Decimal.new("20.00"))
      assert Decimal.equal?(properties.current_value, Decimal.new("1500.00"))
      assert properties.has_warranty == true
      assert properties.warranty_expiry_date == ~D[2025-01-15]
      assert properties.warranty_status == "active"
      assert properties.has_guarantee == false
      assert properties.guarantee_status == "na"
      assert properties.status == "okay"
    end

    test "create_asset_properties/1 with invalid data returns error" do
      assert {:error, %Ecto.Changeset{}} = Resources.create_asset_properties(@invalid_attrs)
    end

    test "create_asset_properties/1 with invalid depreciation method returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:depreciation_method, "invalid_method")

      assert {:error, changeset} = Resources.create_asset_properties(attrs)
      assert "is invalid" in errors_on(changeset).depreciation_method
    end

    test "create_asset_properties/1 with invalid warranty status returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:warranty_status, "invalid_status")

      assert {:error, changeset} = Resources.create_asset_properties(attrs)
      assert "is invalid" in errors_on(changeset).warranty_status
    end

    test "create_asset_properties/1 with invalid guarantee status returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:guarantee_status, "invalid_status")

      assert {:error, changeset} = Resources.create_asset_properties(attrs)
      assert "is invalid" in errors_on(changeset).guarantee_status
    end

    test "create_asset_properties/1 with invalid asset status returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:status, "invalid_status")

      assert {:error, changeset} = Resources.create_asset_properties(attrs)
      assert "is invalid" in errors_on(changeset).status
    end

    test "create_asset_properties/1 with negative purchase cost returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:purchase_cost, Decimal.new("-100"))

      assert {:error, changeset} = Resources.create_asset_properties(attrs)
      assert "must be greater than 0" in errors_on(changeset).purchase_cost
    end

    test "create_asset_properties/1 with negative current value returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:current_value, Decimal.new("-50"))

      assert {:error, changeset} = Resources.create_asset_properties(attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).current_value
    end

    test "get_asset_properties!/1 returns properties", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_asset_properties(attrs)

      fetched = Resources.get_asset_properties!(resource.id)
      assert fetched.resource_id == properties.resource_id
    end

    test "update_asset_properties/2 with valid data updates properties", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_asset_properties(attrs)

      update_attrs = %{current_value: Decimal.new("1200.00"), status: "in_use"}
      assert {:ok, updated} = Resources.update_asset_properties(properties, update_attrs)
      assert Decimal.equal?(updated.current_value, Decimal.new("1200.00"))
      assert updated.status == "in_use"
    end

    test "update_asset_value/2 updates current value", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_asset_properties(attrs)

      assert {:ok, updated} = Resources.update_asset_value(properties, Decimal.new("1000.00"))
      assert Decimal.equal?(updated.current_value, Decimal.new("1000.00"))
    end

    test "update_warranty_status/2 updates warranty status", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_asset_properties(attrs)

      assert {:ok, updated} = Resources.update_warranty_status(properties, "used")
      assert updated.warranty_status == "used"
    end

    test "update_guarantee_status/2 updates guarantee status", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:has_guarantee, true)
      |> Map.put(:guarantee_expiry_date, ~D[2026-01-15])
      |> Map.put(:guarantee_status, "active")

      {:ok, properties} = Resources.create_asset_properties(attrs)

      assert {:ok, updated} = Resources.update_guarantee_status(properties, "used")
      assert updated.guarantee_status == "used"
    end

    test "create_asset_resource/1 creates resource and properties together" do
      attrs = %{
        name: "Company Vehicle",
        resource_category: "asset",
        default_unit_of_measure: "units",
        asset_properties: %{
          purchase_date: ~D[2023-06-01],
          purchase_cost: Decimal.new("25000.00"),
          depreciation_method: "declining_balance",
          depreciation_rate: Decimal.new("15.00"),
          current_value: Decimal.new("25000.00"),
          has_warranty: true,
          warranty_expiry_date: ~D[2026-06-01],
          warranty_status: "active",
          status: "in_use"
        }
      }

      assert {:ok, resource} = Resources.create_asset_resource(attrs)
      assert resource.name == "Company Vehicle"
      assert resource.asset_properties != nil
      assert resource.asset_properties.depreciation_method == "declining_balance"
      assert Decimal.equal?(resource.asset_properties.purchase_cost, Decimal.new("25000.00"))
    end

    test "create_asset_resource/1 rolls back on invalid properties" do
      attrs = %{
        name: "Invalid Asset",
        resource_category: "asset",
        asset_properties: %{
          purchase_date: ~D[2024-01-01],
          purchase_cost: Decimal.new("-500")  # Invalid
        }
      }

      # Count resources before
      count_before = length(Resources.list_resources())

      assert {:error, _changeset} = Resources.create_asset_resource(attrs)
      
      # Verify resource count didn't change
      count_after = length(Resources.list_resources())
      assert count_after == count_before
    end
  end
end
