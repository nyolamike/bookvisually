defmodule BookVisuallyWeb.ResourceJSON do
  alias BookVisually.Resources.Resource

  @doc """
  Renders a list of resources.
  """
  def index(%{resources: resources}) do
    %{data: for(resource <- resources, do: data(resource))}
  end

  @doc """
  Renders a single resource.
  """
  def show(%{resource: resource}) do
    %{data: data(resource)}
  end

  @doc """
  Renders resource history.
  """
  def history(%{resource: resource, history: history}) do
    %{
      data: %{
        resource: data(resource),
        history: history
      }
    }
  end

  defp data(%Resource{} = resource) do
    %{
      id: resource.id,
      name: resource.name,
      resource_category: resource.resource_category,
      default_unit_of_measure: resource.default_unit_of_measure,
      inserted_at: resource.inserted_at,
      updated_at: resource.updated_at
    }
    |> add_category_properties(resource)
  end

  defp add_category_properties(base_data, %Resource{resource_category: "supply"} = resource) do
    case resource.supply_properties do
      %Ecto.Association.NotLoaded{} ->
        base_data

      nil ->
        base_data

      props ->
        Map.put(base_data, :supply_properties, %{
          current_stock_quantity: props.current_stock_quantity,
          out_of_stock_alert_quantity: props.out_of_stock_alert_quantity,
          issues_out_of_stock_alerts: props.issues_out_of_stock_alerts,
          stock_status: props.stock_status
        })
    end
  end

  defp add_category_properties(base_data, %Resource{resource_category: "asset"} = resource) do
    case resource.asset_properties do
      %Ecto.Association.NotLoaded{} ->
        base_data

      nil ->
        base_data

      props ->
        Map.put(base_data, :asset_properties, %{
          purchase_date: props.purchase_date,
          purchase_cost: props.purchase_cost,
          current_value: props.current_value,
          depreciation_method: props.depreciation_method,
          status: props.status,
          warranty_expiry_date: props.warranty_expiry_date,
          warranty_status: props.warranty_status,
          guarantee_expiry_date: props.guarantee_expiry_date,
          guarantee_status: props.guarantee_status
        })
    end
  end

  defp add_category_properties(base_data, %Resource{resource_category: "subscription"} = resource) do
    case resource.subscription_properties do
      %Ecto.Association.NotLoaded{} ->
        base_data

      nil ->
        base_data

      props ->
        Map.put(base_data, :subscription_properties, %{
          vendor: props.vendor,
          package: props.package,
          subscription_period_start: props.subscription_period_start,
          subscription_period_end: props.subscription_period_end,
          status: props.status
        })
    end
  end

  defp add_category_properties(base_data, %Resource{resource_category: "utility"} = resource) do
    case resource.utility_properties do
      %Ecto.Association.NotLoaded{} ->
        base_data

      nil ->
        base_data

      props ->
        Map.put(base_data, :utility_properties, %{
          bill_type: props.bill_type,
          billing_cycle_days: props.billing_cycle_days,
          last_bill_date: props.last_bill_date,
          next_bill_date: props.next_bill_date,
          last_consumption_quantity: props.last_consumption_quantity,
          bill_status: props.bill_status
        })
    end
  end

  defp add_category_properties(base_data, _resource), do: base_data
end
