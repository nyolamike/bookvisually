defmodule BookVisuallyWeb.BillJSON do
  alias BookVisually.Bills.UtilityBill

  @doc """
  Renders a list of bills.
  """
  def index(%{bills: bills}) do
    %{data: for(bill <- bills, do: data(bill))}
  end

  @doc """
  Renders a single bill.
  """
  def show(%{bill: bill}) do
    %{data: data(bill)}
  end

  @doc """
  Renders bill with payment details.
  """
  def show_with_payment(%{bill: bill, expense: expense, transaction: transaction}) do
    %{
      data: %{
        bill: data(bill),
        expense: %{
          id: expense.id,
          total_amount: expense.total_amount,
          description: expense.description
        },
        transaction: %{
          id: transaction.id,
          amount: transaction.amount,
          from_account_id: transaction.from_account_id,
          transaction_date: transaction.transaction_date
        }
      }
    }
  end

  defp data(%UtilityBill{} = bill) do
    %{
      id: bill.id,
      resource_id: bill.resource_id,
      bill_date: bill.bill_date,
      due_date: bill.due_date,
      previous_reading: bill.previous_reading,
      bill_reading: bill.bill_reading,
      unit_of_measure: bill.unit_of_measure,
      unit_cost: bill.unit_cost,
      total_amount: bill.total_amount,
      status: bill.status,
      vendor: bill.vendor,
      notes: bill.notes,
      inserted_at: bill.inserted_at,
      updated_at: bill.updated_at
    }
  end
end
