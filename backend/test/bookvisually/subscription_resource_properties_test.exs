defmodule BookVisually.SubscriptionResourcePropertiesTest do
  use BookVisually.DataCase

  alias BookVisually.Resources
  alias BookVisually.Resources.SubscriptionResourceProperties

  describe "subscription_resource_properties" do
    setup do
      {:ok, resource} = Resources.create_resource(%{
        name: "Internet Data Plan",
        resource_category: "subscription",
        default_unit_of_measure: "months"
      })

      %{resource: resource}
    end

    @valid_attrs %{
      renewal_period: "monthly",
      vendor: "TelecomCo",
      package: "Premium 100GB",
      issues_expiry_alerts: true,
      days_left_to_alert: 7,
      current_subscription_start_date: ~D[2026-03-01],
      current_subscription_end_date: ~D[2026-04-01],
      status: "active"
    }

    @invalid_attrs %{
      resource_id: nil,
      vendor: nil,
      package: nil
    }

    test "create_subscription_properties/1 with valid data creates properties", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)

      assert {:ok, %SubscriptionResourceProperties{} = properties} = Resources.create_subscription_properties(attrs)
      assert properties.resource_id == resource.id
      assert properties.renewal_period == "monthly"
      assert properties.vendor == "TelecomCo"
      assert properties.package == "Premium 100GB"
      assert properties.issues_expiry_alerts == true
      assert properties.days_left_to_alert == 7
      assert properties.current_subscription_start_date == ~D[2026-03-01]
      assert properties.current_subscription_end_date == ~D[2026-04-01]
      assert properties.status == "active"
    end

    test "create_subscription_properties/1 with invalid data returns error" do
      assert {:error, %Ecto.Changeset{}} = Resources.create_subscription_properties(@invalid_attrs)
    end

    test "create_subscription_properties/1 with invalid status returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:status, "invalid_status")

      assert {:error, changeset} = Resources.create_subscription_properties(attrs)
      assert "is invalid" in errors_on(changeset).status
    end

    test "get_subscription_properties!/1 returns properties", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_subscription_properties(attrs)

      fetched = Resources.get_subscription_properties!(resource.id)
      assert fetched.resource_id == properties.resource_id
    end

    test "update_subscription_properties/2 with valid data updates properties", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_subscription_properties(attrs)

      update_attrs = %{days_left_to_alert: 14, package: "Premium 200GB"}
      assert {:ok, updated} = Resources.update_subscription_properties(properties, update_attrs)
      assert updated.days_left_to_alert == 14
      assert updated.package == "Premium 200GB"
    end

    test "update_subscription_period/3 updates subscription dates and status", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:status, "expired")

      {:ok, properties} = Resources.create_subscription_properties(attrs)

      new_start = ~D[2026-04-01]
      new_end = ~D[2026-05-01]

      assert {:ok, updated} = Resources.update_subscription_period(properties, new_start, new_end)
      assert updated.current_subscription_start_date == new_start
      assert updated.current_subscription_end_date == new_end
      assert updated.status == "active"
    end

    test "expire_subscription/1 sets status to expired", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_subscription_properties(attrs)

      assert {:ok, updated} = Resources.expire_subscription(properties)
      assert updated.status == "expired"
    end

    test "cancel_subscription/1 sets status to cancelled", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, properties} = Resources.create_subscription_properties(attrs)

      assert {:ok, updated} = Resources.cancel_subscription(properties)
      assert updated.status == "cancelled"
    end

    test "create_subscription_resource/1 creates resource and properties together" do
      attrs = %{
        name: "Cloud Storage",
        resource_category: "subscription",
        default_unit_of_measure: "months",
        subscription_properties: %{
          renewal_period: "yearly",
          vendor: "CloudProvider",
          package: "Business 1TB",
          issues_expiry_alerts: true,
          days_left_to_alert: 30
        }
      }

      assert {:ok, resource} = Resources.create_subscription_resource(attrs)
      assert resource.name == "Cloud Storage"
      assert resource.subscription_properties != nil
      assert resource.subscription_properties.renewal_period == "yearly"
      assert resource.subscription_properties.vendor == "CloudProvider"
    end

    test "create_subscription_resource/1 rolls back on invalid properties" do
      attrs = %{
        name: "Invalid Subscription",
        resource_category: "subscription",
        subscription_properties: %{
          vendor: nil,  # Invalid - required
          package: nil  # Invalid - required
        }
      }

      count_before = length(Resources.list_resources())

      assert {:error, _changeset} = Resources.create_subscription_resource(attrs)
      
      count_after = length(Resources.list_resources())
      assert count_after == count_before
    end
  end
end
