defmodule BookVisuallyWeb.DashboardController do
  use BookVisuallyWeb, :controller

  alias BookVisually.Accounts
  alias BookVisually.Resources
  alias BookVisually.Bills

  action_fallback BookVisuallyWeb.FallbackController

  @doc """
  Returns dashboard summary with total balance, cash flow, alerts, and recent activity.
  """
  def show(conn, _params) do
    total_balance = Accounts.calculate_total_balance()
    accounts = Accounts.list_accounts()

    # Calculate total cash in/out across all accounts
    {total_cash_in, total_cash_out} =
      Enum.reduce(accounts, {Decimal.new(0), Decimal.new(0)}, fn account, {cash_in, cash_out} ->
        {
          Decimal.add(cash_in, account.total_cash_in),
          Decimal.add(cash_out, account.total_cash_out)
        }
      end)

    # Get alerts
    low_stock_supplies = get_low_stock_supplies()
    overdue_bills = Bills.list_overdue_bills()
    upcoming_bills = Bills.list_upcoming_bills(7)

    # Get recent activity (last 10 transactions)
    recent_transactions = Accounts.list_transactions() |> Enum.take(10)

    render(conn, :show,
      total_balance: total_balance,
      total_cash_in: total_cash_in,
      total_cash_out: total_cash_out,
      low_stock_supplies: low_stock_supplies,
      overdue_bills: overdue_bills,
      upcoming_bills: upcoming_bills,
      recent_transactions: recent_transactions
    )
  end

  @doc """
  Returns all active alerts.
  """
  def alerts(conn, _params) do
    low_stock_supplies = get_low_stock_supplies()
    overdue_bills = Bills.list_overdue_bills()
    upcoming_bills = Bills.list_upcoming_bills(7)

    render(conn, :alerts,
      low_stock_supplies: low_stock_supplies,
      overdue_bills: overdue_bills,
      upcoming_bills: upcoming_bills
    )
  end

  @doc """
  Returns recent activity feed.
  """
  def activity_feed(conn, params) do
    limit = Map.get(params, "limit", "20") |> String.to_integer()
    recent_transactions = Accounts.list_transactions() |> Enum.take(limit)

    render(conn, :activity_feed, transactions: recent_transactions)
  end

  defp get_low_stock_supplies do
    Resources.list_resources_by_category("supply")
    |> Enum.filter(fn resource ->
      case resource.supply_properties do
        %Ecto.Association.NotLoaded{} -> false
        nil -> false
        props -> props.status in ["low_stock", "out_of_stock"]
      end
    end)
  end
end
