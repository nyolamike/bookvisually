defmodule BookVisually.Resources do
  @moduledoc """
  The Resources context.
  Handles all business logic for managing resources (subscriptions, utilities, supplies, assets).
  """

  import Ecto.Query, warn: false
  alias BookVisually.Repo
  alias BookVisually.Resources.Resource
  alias BookVisually.Resources.SupplyResourceProperties
  alias BookVisually.Resources.AssetResourceProperties
  alias BookVisually.Resources.SubscriptionResourceProperties
  alias BookVisually.Resources.UtilityResourceProperties

  @doc """
  Returns the list of active resources.

  ## Examples

      iex> list_resources()
      [%Resource{}, ...]

  """
  def list_resources do
    Resource.active()
    |> Repo.all()
    |> Repo.preload([:supply_properties, :asset_properties, :subscription_properties, :utility_properties])
  end

  @doc """
  Returns the list of resources by category.

  ## Examples

      iex> list_resources_by_category("supply")
      [%Resource{}, ...]

  """
  def list_resources_by_category(category) do
    Resource.active()
    |> Resource.by_category(category)
    |> Repo.all()
    |> Repo.preload([:supply_properties, :asset_properties, :subscription_properties, :utility_properties])
  end

  @doc """
  Gets a single resource.

  Raises `Ecto.NoResultsError` if the Resource does not exist or is deleted.

  ## Examples

      iex> get_resource!(123)
      %Resource{}

      iex> get_resource!(456)
      ** (Ecto.NoResultsError)

  """
  def get_resource!(id) do
    Resource.active()
    |> Repo.get!(id)
  end

  @doc """
  Gets a single resource, including deleted ones.

  ## Examples

      iex> get_resource_with_deleted!(123)
      %Resource{}

  """
  def get_resource_with_deleted!(id) do
    Resource.with_deleted()
    |> Repo.get!(id)
  end

  @doc """
  Creates a resource.

  ## Examples

      iex> create_resource(%{name: "Varnish", resource_category: "supply"})
      {:ok, %Resource{}}

      iex> create_resource(%{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_resource(attrs \\ %{}) do
    %Resource{}
    |> Resource.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a resource.

  ## Examples

      iex> update_resource(resource, %{name: "New Name"})
      {:ok, %Resource{}}

      iex> update_resource(resource, %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_resource(%Resource{} = resource, attrs) do
    resource
    |> Resource.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Soft deletes a resource.

  ## Examples

      iex> soft_delete_resource(resource)
      {:ok, %Resource{}}

  """
  def soft_delete_resource(%Resource{} = resource) do
    resource
    |> Resource.soft_delete_changeset()
    |> Repo.update()
  end

  @doc """
  Restores a soft-deleted resource.

  ## Examples

      iex> restore_resource(resource)
      {:ok, %Resource{}}

  """
  def restore_resource(%Resource{} = resource) do
    resource
    |> Resource.restore_changeset()
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resource changes.

  ## Examples

      iex> change_resource(resource)
      %Ecto.Changeset{data: %Resource{}}

  """
  def change_resource(%Resource{} = resource, attrs \\ %{}) do
    Resource.changeset(resource, attrs)
  end

  # Supply Resource Properties

  @doc """
  Creates supply properties for a resource.

  ## Examples

      iex> create_supply_properties(%{resource_id: resource.id, out_of_stock_alert_quantity: 10})
      {:ok, %SupplyResourceProperties{}}

  """
  def create_supply_properties(attrs \\ %{}) do
    %SupplyResourceProperties{}
    |> SupplyResourceProperties.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets supply properties for a resource.

  ## Examples

      iex> get_supply_properties!(resource_id)
      %SupplyResourceProperties{}

  """
  def get_supply_properties!(resource_id) do
    Repo.get!(SupplyResourceProperties, resource_id)
  end

  @doc """
  Updates supply properties.

  ## Examples

      iex> update_supply_properties(properties, %{out_of_stock_alert_quantity: 5})
      {:ok, %SupplyResourceProperties{}}

  """
  def update_supply_properties(%SupplyResourceProperties{} = properties, attrs) do
    properties
    |> SupplyResourceProperties.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates stock quantity and automatically adjusts status.

  ## Examples

      iex> update_stock_quantity(properties, Decimal.new("50"))
      {:ok, %SupplyResourceProperties{}}

  """
  def update_stock_quantity(%SupplyResourceProperties{} = properties, new_quantity) do
    properties
    |> SupplyResourceProperties.update_stock_changeset(new_quantity)
    |> Repo.update()
  end

  @doc """
  Creates a supply resource with its properties in a transaction.

  ## Examples

      iex> create_supply_resource(%{
        name: "Varnish",
        resource_category: "supply",
        supply_properties: %{out_of_stock_alert_quantity: 10}
      })
      {:ok, %Resource{}}

  """
  def create_supply_resource(attrs) do
    Repo.transaction(fn ->
      with {:ok, resource} <- create_resource(attrs),
           supply_attrs <- Map.get(attrs, :supply_properties, %{}) |> Map.put(:resource_id, resource.id),
           {:ok, _properties} <- create_supply_properties(supply_attrs) do
        resource |> Repo.preload(:supply_properties)
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  # Asset Resource Properties

  @doc """
  Creates asset properties for a resource.

  ## Examples

      iex> create_asset_properties(%{resource_id: resource.id, purchase_date: ~D[2024-01-01], purchase_cost: 1500})
      {:ok, %AssetResourceProperties{}}

  """
  def create_asset_properties(attrs \\ %{}) do
    %AssetResourceProperties{}
    |> AssetResourceProperties.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets asset properties for a resource.

  ## Examples

      iex> get_asset_properties!(resource_id)
      %AssetResourceProperties{}

  """
  def get_asset_properties!(resource_id) do
    Repo.get!(AssetResourceProperties, resource_id)
  end

  @doc """
  Updates asset properties.

  ## Examples

      iex> update_asset_properties(properties, %{current_value: 1200})
      {:ok, %AssetResourceProperties{}}

  """
  def update_asset_properties(%AssetResourceProperties{} = properties, attrs) do
    properties
    |> AssetResourceProperties.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the current value of an asset.

  ## Examples

      iex> update_asset_value(properties, Decimal.new("1000"))
      {:ok, %AssetResourceProperties{}}

  """
  def update_asset_value(%AssetResourceProperties{} = properties, new_value) do
    properties
    |> AssetResourceProperties.update_value_changeset(new_value)
    |> Repo.update()
  end

  @doc """
  Updates warranty status.

  ## Examples

      iex> update_warranty_status(properties, "used")
      {:ok, %AssetResourceProperties{}}

  """
  def update_warranty_status(%AssetResourceProperties{} = properties, new_status) do
    properties
    |> AssetResourceProperties.update_warranty_status_changeset(new_status)
    |> Repo.update()
  end

  @doc """
  Updates guarantee status.

  ## Examples

      iex> update_guarantee_status(properties, "used")
      {:ok, %AssetResourceProperties{}}

  """
  def update_guarantee_status(%AssetResourceProperties{} = properties, new_status) do
    properties
    |> AssetResourceProperties.update_guarantee_status_changeset(new_status)
    |> Repo.update()
  end

  @doc """
  Creates an asset resource with its properties in a transaction.

  ## Examples

      iex> create_asset_resource(%{
        name: "Laptop",
        resource_category: "asset",
        asset_properties: %{purchase_date: ~D[2024-01-01], purchase_cost: 1500}
      })
      {:ok, %Resource{}}

  """
  def create_asset_resource(attrs) do
    Repo.transaction(fn ->
      with {:ok, resource} <- create_resource(attrs),
           asset_attrs <- Map.get(attrs, :asset_properties, %{}) |> Map.put(:resource_id, resource.id),
           {:ok, _properties} <- create_asset_properties(asset_attrs) do
        resource |> Repo.preload(:asset_properties)
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  # Subscription Resource Properties

  @doc """
  Creates subscription properties for a resource.

  ## Examples

      iex> create_subscription_properties(%{resource_id: resource.id, vendor: "TelecomCo", package: "Premium"})
      {:ok, %SubscriptionResourceProperties{}}

  """
  def create_subscription_properties(attrs \\ %{}) do
    %SubscriptionResourceProperties{}
    |> SubscriptionResourceProperties.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets subscription properties for a resource.

  ## Examples

      iex> get_subscription_properties!(resource_id)
      %SubscriptionResourceProperties{}

  """
  def get_subscription_properties!(resource_id) do
    Repo.get!(SubscriptionResourceProperties, resource_id)
  end

  @doc """
  Updates subscription properties.

  ## Examples

      iex> update_subscription_properties(properties, %{package: "Premium Plus"})
      {:ok, %SubscriptionResourceProperties{}}

  """
  def update_subscription_properties(%SubscriptionResourceProperties{} = properties, attrs) do
    properties
    |> SubscriptionResourceProperties.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates subscription period and sets status to active.

  ## Examples

      iex> update_subscription_period(properties, ~D[2026-04-01], ~D[2026-05-01])
      {:ok, %SubscriptionResourceProperties{}}

  """
  def update_subscription_period(%SubscriptionResourceProperties{} = properties, start_date, end_date) do
    properties
    |> SubscriptionResourceProperties.update_period_changeset(start_date, end_date)
    |> Repo.update()
  end

  @doc """
  Expires a subscription.

  ## Examples

      iex> expire_subscription(properties)
      {:ok, %SubscriptionResourceProperties{}}

  """
  def expire_subscription(%SubscriptionResourceProperties{} = properties) do
    properties
    |> SubscriptionResourceProperties.expire_changeset()
    |> Repo.update()
  end

  @doc """
  Cancels a subscription.

  ## Examples

      iex> cancel_subscription(properties)
      {:ok, %SubscriptionResourceProperties{}}

  """
  def cancel_subscription(%SubscriptionResourceProperties{} = properties) do
    properties
    |> SubscriptionResourceProperties.cancel_changeset()
    |> Repo.update()
  end

  @doc """
  Creates a subscription resource with its properties in a transaction.

  ## Examples

      iex> create_subscription_resource(%{
        name: "Internet Plan",
        resource_category: "subscription",
        subscription_properties: %{vendor: "TelecomCo", package: "Premium"}
      })
      {:ok, %Resource{}}

  """
  def create_subscription_resource(attrs) do
    Repo.transaction(fn ->
      with {:ok, resource} <- create_resource(attrs),
           subscription_attrs <- Map.get(attrs, :subscription_properties, %{}) |> Map.put(:resource_id, resource.id),
           {:ok, _properties} <- create_subscription_properties(subscription_attrs) do
        resource |> Repo.preload(:subscription_properties)
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  # Utility Resource Properties

  @doc """
  Creates utility properties for a resource.

  ## Examples

      iex> create_utility_properties(%{resource_id: resource.id, bill_type: "utility"})
      {:ok, %UtilityResourceProperties{}}

  """
  def create_utility_properties(attrs \\ %{}) do
    %UtilityResourceProperties{}
    |> UtilityResourceProperties.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets utility properties for a resource.

  ## Examples

      iex> get_utility_properties!(resource_id)
      %UtilityResourceProperties{}

  """
  def get_utility_properties!(resource_id) do
    Repo.get!(UtilityResourceProperties, resource_id)
  end

  @doc """
  Updates utility properties.

  ## Examples

      iex> update_utility_properties(properties, %{billing_cycle_days: 28})
      {:ok, %UtilityResourceProperties{}}

  """
  def update_utility_properties(%UtilityResourceProperties{} = properties, attrs) do
    properties
    |> UtilityResourceProperties.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates bill status.

  ## Examples

      iex> update_bill_status(properties, "unpaid")
      {:ok, %UtilityResourceProperties{}}

  """
  def update_bill_status(%UtilityResourceProperties{} = properties, new_status) do
    properties
    |> UtilityResourceProperties.update_status_changeset(new_status)
    |> Repo.update()
  end

  @doc """
  Updates bill dates.

  ## Examples

      iex> update_bill_dates(properties, ~D[2026-03-01], ~D[2026-04-01])
      {:ok, %UtilityResourceProperties{}}

  """
  def update_bill_dates(%UtilityResourceProperties{} = properties, last_date, next_date) do
    properties
    |> UtilityResourceProperties.update_dates_changeset(last_date, next_date)
    |> Repo.update()
  end

  @doc """
  Updates consumption quantity.

  ## Examples

      iex> update_consumption(properties, Decimal.new("200"))
      {:ok, %UtilityResourceProperties{}}

  """
  def update_consumption(%UtilityResourceProperties{} = properties, quantity) do
    properties
    |> UtilityResourceProperties.update_consumption_changeset(quantity)
    |> Repo.update()
  end

  @doc """
  Creates a utility resource with its properties in a transaction.

  ## Examples

      iex> create_utility_resource(%{
        name: "Water Bill",
        resource_category: "utility",
        utility_properties: %{bill_type: "utility"}
      })
      {:ok, %Resource{}}

  """
  def create_utility_resource(attrs) do
    Repo.transaction(fn ->
      with {:ok, resource} <- create_resource(attrs),
           utility_attrs <- Map.get(attrs, :utility_properties, %{}) |> Map.put(:resource_id, resource.id),
           {:ok, _properties} <- create_utility_properties(utility_attrs) do
        resource |> Repo.preload(:utility_properties)
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end
end