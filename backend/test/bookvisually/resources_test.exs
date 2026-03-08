defmodule BookVisually.ResourcesTest do
  use BookVisually.DataCase

  alias BookVisually.Resources

  describe "resources" do
    alias BookVisually.Resources.Resource

    @valid_attrs %{
      name: "Wood Varnish",
      description: "High quality wood varnish",
      resource_category: "supply",
      default_unit_of_measure: "liters",
      default_unit_cost: Decimal.new("15.50")
    }

    @invalid_attrs %{
      name: nil,
      resource_category: nil
    }

    def resource_fixture(attrs \\ %{}) do
      {:ok, resource} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Resources.create_resource()

      resource
    end

    test "list_resources/0 returns all active resources" do
      resource = resource_fixture()
      assert Resources.list_resources() == [resource]
    end

    test "list_resources/0 does not return deleted resources" do
      resource = resource_fixture()
      {:ok, _deleted} = Resources.soft_delete_resource(resource)
      assert Resources.list_resources() == []
    end

    test "list_resources_by_category/1 returns resources of specific category" do
      supply = resource_fixture(%{resource_category: "supply"})
      _asset = resource_fixture(%{name: "Laptop", resource_category: "asset"})

      assert Resources.list_resources_by_category("supply") == [supply]
    end

    test "get_resource!/1 returns the resource with given id" do
      resource = resource_fixture()
      assert Resources.get_resource!(resource.id) == resource
    end

    test "get_resource!/1 raises error for deleted resource" do
      resource = resource_fixture()
      {:ok, _deleted} = Resources.soft_delete_resource(resource)

      assert_raise Ecto.NoResultsError, fn ->
        Resources.get_resource!(resource.id)
      end
    end

    test "get_resource_with_deleted!/1 returns deleted resource" do
      resource = resource_fixture()
      {:ok, deleted} = Resources.soft_delete_resource(resource)

      fetched = Resources.get_resource_with_deleted!(resource.id)
      assert fetched.id == deleted.id
      assert fetched.is_deleted == true
    end

    test "create_resource/1 with valid data creates a resource" do
      assert {:ok, %Resource{} = resource} = Resources.create_resource(@valid_attrs)
      assert resource.name == "Wood Varnish"
      assert resource.resource_category == "supply"
      assert resource.default_unit_of_measure == "liters"
      assert Decimal.equal?(resource.default_unit_cost, Decimal.new("15.50"))
      assert resource.is_deleted == false
      assert resource.deleted_at == nil
    end

    test "create_resource/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Resources.create_resource(@invalid_attrs)
    end

    test "create_resource/1 with invalid category returns error" do
      attrs = Map.put(@valid_attrs, :resource_category, "invalid")
      assert {:error, changeset} = Resources.create_resource(attrs)
      assert "is invalid" in errors_on(changeset).resource_category
    end

    test "create_resource/1 with negative cost returns error" do
      attrs = Map.put(@valid_attrs, :default_unit_cost, Decimal.new("-10"))
      assert {:error, changeset} = Resources.create_resource(attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).default_unit_cost
    end

    test "create_resource/1 with inspection enabled requires interval" do
      attrs = Map.merge(@valid_attrs, %{
        needs_periodic_inspection: true,
        inspection_interval_days: nil
      })

      assert {:error, changeset} = Resources.create_resource(attrs)
      assert "is required when periodic inspection is enabled" in errors_on(changeset).inspection_interval_days
    end

    test "create_resource/1 with inspection enabled and interval succeeds" do
      attrs = Map.merge(@valid_attrs, %{
        needs_periodic_inspection: true,
        inspection_interval_days: 30
      })

      assert {:ok, %Resource{} = resource} = Resources.create_resource(attrs)
      assert resource.needs_periodic_inspection == true
      assert resource.inspection_interval_days == 30
    end

    test "update_resource/2 with valid data updates the resource" do
      resource = resource_fixture()
      update_attrs = %{name: "Updated Varnish", default_unit_cost: Decimal.new("20.00")}

      assert {:ok, %Resource{} = resource} = Resources.update_resource(resource, update_attrs)
      assert resource.name == "Updated Varnish"
      assert Decimal.equal?(resource.default_unit_cost, Decimal.new("20.00"))
    end

    test "update_resource/2 with invalid data returns error changeset" do
      resource = resource_fixture()
      assert {:error, %Ecto.Changeset{}} = Resources.update_resource(resource, @invalid_attrs)
      assert resource == Resources.get_resource!(resource.id)
    end

    test "soft_delete_resource/1 marks resource as deleted" do
      resource = resource_fixture()
      assert {:ok, %Resource{} = deleted} = Resources.soft_delete_resource(resource)
      assert deleted.is_deleted == true
      assert deleted.deleted_at != nil
      assert [] == Resources.list_resources()
    end

    test "restore_resource/1 restores a deleted resource" do
      resource = resource_fixture()
      {:ok, deleted} = Resources.soft_delete_resource(resource)
      assert {:ok, %Resource{} = restored} = Resources.restore_resource(deleted)
      assert restored.is_deleted == false
      assert restored.deleted_at == nil
      assert [restored] == Resources.list_resources()
    end

    test "change_resource/1 returns a resource changeset" do
      resource = resource_fixture()
      assert %Ecto.Changeset{} = Resources.change_resource(resource)
    end
  end
end
