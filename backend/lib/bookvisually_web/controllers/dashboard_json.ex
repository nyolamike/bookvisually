defmodule BookVisuallyWeb.DashboardJSON do
  @doc """
  Renders dashboard summary.
  """
  def show(assigns) do
    %{
      data: %{
        total_balance: assigns.total_balance,
        total_cash_in: assigns.total_cash_in,
        total_cash_out: assigns.total_cash_out,
        alerts: %{
          low_stock: for(supply <- assigns.low_stock_supplies, do: supply_alert(supply)),
          overdue_bills: for(bill <- assigns.overdue_bills, do: bill_alert(bill)),
          upcoming_bills: for(bill <- assigns.upcoming_bills, do: bill_alert(bill))
        },
        recent_activity: for(transaction <- assigns.recent_transactions, do: transaction_summary(transaction))
      }
    }
  end

  @doc """
  Renders alerts only.
  """
  def alerts(assigns) do
    %{
      data: %{
        low_stock: for(supply <- assigns.low_stock_supplies, do: supply_alert(supply)),
        overdue_bills: for(bill <- assigns.overdue_bills, do: bill_alert(bill)),
        upcoming_bills: for(bill <- assigns.upcoming_bills, do: bill_alert(bill))
      }
    }
  end

  @doc """
  Renders activity feed.
  """
  def activity_feed(%{transactions: transactions}) do
    %{data: for(transaction <- transactions, do: transaction_summary(transaction))}
  end

  defp supply_alert(resource) do
    props = resource.supply_properties

    %{
      resource_id: resource.id,
      name: resource.name,
      current_stock: props.current_stock_quantity,
      alert_threshold: props.out_of_stock_alert_quantity,
      status: props.stock_status,
      unit: resource.default_unit_of_measure
    }
  end

  defp bill_alert(bill) do
    %{
      bill_id: bill.id,
      resource_id: bill.resource_id,
      vendor: bill.vendor,
      amount: bill.total_amount,
      due_date: bill.due_date,
      status: bill.status,
      days_until_due: Date.diff(bill.due_date, Date.utc_today())
    }
  end

  defp transaction_summary(transaction) do
    %{
      id: transaction.id,
      type: transaction.transaction_type,
      amount: transaction.amount,
      description: transaction.description,
      date: transaction.transaction_date,
      from_account_id: transaction.from_account_id,
      to_account_id: transaction.to_account_id
    }
  end
end
