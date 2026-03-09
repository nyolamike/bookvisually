defmodule BookVisually.UtilityResourcePropertiesTest do
  use BookVisually.DataCase

  alias BookVisually.Resources
  alias BookVisually.Resources.UtilityResourceProperties

  describe "utility_resource_properties" do
    setup do
      {:ok, resource} = Resources.create_resource(%{
        name: "Water Bill",
        resource_category: "utility",
        default_unit_of_measure: "liters"
      })

      %{resource: resource}
    end

    @valid_attrs %{
      bill_type: "utility",
      billing_cycle_days: 30,
      issues_bill_due_alerts: true,
      days_to_due_date_alert: 5,
      current_bill_status: "paid",
      last_bill_date: ~D[2026-02-01],
      next_bill_due_date: ~D[2026-03-01],
      current_bill_quantity_consumed: Decimal.new("150.5")
    }

    @invalid_attrs %{
      resource_id: nil,
      bill_type: nil
    }

    test "create_utility_properties/1 with valid data creates properties", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)

      assert {:ok, %UtilityResourceProperties{} = properties} = Resources.create_utility_properties(attrs)
      assert properties.resource_id == resource.id
      assert properties.bill_type == "utility"
      assert properties.billing_cycle_days == 30
      assert properties.issues_bill_due_alerts == true
      assert properties.days_to_due_date_alert == 5
      assert properties.current_bill_status == "paid"
      assert properties.last_bill_date == ~D[2026-02-01]
      assert properties.next_bill_due_date == ~D[2026-03-01]
      assert Decimal.equal?(properties.current_bill_quantity_consumed, Decimal.new("150.5"))
    end

    test "create_utility_properties/1 with invalid data returns error" do
      assert {:error, %Ecto.Changeset{}} = Resources.create_utility_properties(@invalid_attrs)
    end

    test "create_utility_properties/1 with invalid bill_type returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:bill_type, "invalid_type")

      assert {:error, changeset} = Resources.create_utility_properties(attrs)
      assert "is invalid" in errors_on(changeset).bill_type
    end

    test "create_utility_properties/1 with invalid current_bill_status returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:current_bill_status, "invalid_status")

      assert {:error, changeset} = Resources.create_utility_properties(attrs)
      assert "is invalid" in errors_on(changeset).current_bill_status
    end

    test "get_utility_properties!/1 returns properties", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_utility_properties(attrs)

      fetched = Resources.get_utility_properties!(resource.id)
      assert fetched.resource_id == properties.resource_id
    end

    test "update_utility_properties/2 with valid data updates properties", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_utility_properties(attrs)

      update_attrs = %{days_to_due_date_alert: 7, billing_cycle_days: 28}
      assert {:ok, updated} = Resources.update_utility_properties(properties, update_attrs)
      assert updated.days_to_due_date_alert == 7
      assert updated.billing_cycle_days == 28
    end

    test "update_bill_status/2 updates bill status", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_utility_properties(attrs)

      assert {:ok, updated} = Resources.update_bill_status(properties, "unpaid")
      assert updated.current_bill_status == "unpaid"
    end

    test "update_bill_dates/3 updates bill dates", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_utility_properties(attrs)

      new_last = ~D[2026-03-01]
      new_next = ~D[2026-04-01]

      assert {:ok, updated} = Resources.update_bill_dates(properties, new_last, new_next)
      assert updated.last_bill_date == new_last
      assert updated.next_bill_due_date == new_next
    end

    test "update_consumption/2 updates quantity consumed", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_utility_properties(attrs)

      assert {:ok, updated} = Resources.update_consumption(properties, Decimal.new("200.0"))
      assert Decimal.equal?(updated.current_bill_quantity_consumed, Decimal.new("200.0"))
    end

    test "create_utility_resource/1 creates resource and properties together" do
      attrs = %{
        name: "Electricity Bill",
        resource_category: "utility",
        default_unit_of_measure: "kWh",
        utility_properties: %{
          bill_type: "utility",
          billing_cycle_days: 30,
          issues_bill_due_alerts: true,
          days_to_due_date_alert: 3
        }
      }

      assert {:ok, resource} = Resources.create_utility_resource(attrs)
      assert resource.name == "Electricity Bill"
      assert resource.utility_properties != nil
      assert resource.utility_properties.bill_type == "utility"
      assert resource.utility_properties.billing_cycle_days == 30
    end

    test "create_utility_resource/1 rolls back on invalid properties" do
      attrs = %{
        name: "Invalid Utility",
        resource_category: "utility",
        utility_properties: %{
          bill_type: "invalid_type"  # Invalid
        }
      }

      count_before = length(Resources.list_resources())

      assert {:error, _changeset} = Resources.create_utility_resource(attrs)
      
      count_after = length(Resources.list_resources())
      assert count_after == count_before
    end
  end
end
