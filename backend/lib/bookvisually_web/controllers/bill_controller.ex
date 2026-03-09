defmodule BookVisuallyWeb.BillController do
  use BookVisuallyWeb, :controller

  alias BookVisually.Bills
  alias BookVisually.Bills.UtilityBill
  alias BookVisually.Expenses
  alias BookVisually.Accounts
  alias BookVisually.Repo

  action_fallback BookVisuallyWeb.FallbackController

  def index(conn, _params) do
    bills = Bills.list_bills()
    render(conn, :index, bills: bills)
  end

  def create(conn, %{"bill" => bill_params}) do
    with {:ok, %UtilityBill{} = bill} <- Bills.create_bill(bill_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/bills/#{bill}")
      |> render(:show, bill: bill)
    end
  end

  def show(conn, %{"id" => id}) do
    bill = Bills.get_bill!(id)
    render(conn, :show, bill: bill)
  end

  def update(conn, %{"id" => id, "bill" => bill_params}) do
    bill = Bills.get_bill!(id)

    with {:ok, %UtilityBill{} = bill} <- Bills.update_bill(bill, bill_params) do
      render(conn, :show, bill: bill)
    end
  end

  def delete(conn, %{"id" => id}) do
    bill = Bills.get_bill!(id)

    with {:ok, %UtilityBill{}} <- Bills.soft_delete_bill(bill) do
      send_resp(conn, :no_content, "")
    end
  end

  @doc """
  Batch operation: Pay bill + create expense + create transaction.
  This is the key operation for the visual workflow where money flows from account
  to bill payment and bill status updates atomically.
  """
  def pay(conn, %{"id" => bill_id, "paid_from_account_id" => account_id} = params) do
    result =
      Repo.transaction(fn ->
        bill = Bills.get_bill!(bill_id)

        # Step 1: Create expense for the bill payment
        expense_params = %{
          resource_id: bill.resource_id,
          expense_date: params["payment_date"] || Date.utc_today(),
          unit_cost: bill.unit_cost,
          quantity: Decimal.to_float(bill.bill_reading) - Decimal.to_float(bill.previous_reading),
          unit_of_measure: bill.unit_of_measure,
          total_amount: bill.total_amount,
          description: "Payment for bill ##{bill.id} - #{bill.vendor}",
          notes: "Bill payment"
        }

        with {:ok, expense} <- Expenses.create_expense(expense_params),
             # Step 2: Create payment transaction
             transaction_params = %{
               from_account_id: account_id,
               amount: bill.total_amount,
               description: "Bill payment: #{bill.vendor}",
               transaction_date: params["payment_date"] || DateTime.utc_now(),
               expense_id: expense.id
             },
             {:ok, transaction} <- Accounts.create_expense_payment(transaction_params),
             # Step 3: Update bill status to paid
             {:ok, updated_bill} <- Bills.mark_as_paid(bill) do
          {updated_bill, expense, transaction}
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)

    case result do
      {:ok, {bill, expense, transaction}} ->
        conn
        |> put_status(:ok)
        |> render(:show_with_payment, bill: bill, expense: expense, transaction: transaction)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def overdue(conn, _params) do
    bills = Bills.list_overdue_bills()
    render(conn, :index, bills: bills)
  end

  def upcoming(conn, %{"days" => days}) do
    {days_int, _} = Integer.parse(days)
    bills = Bills.list_upcoming_bills(days_int)
    render(conn, :index, bills: bills)
  end

  def upcoming(conn, _params) do
    bills = Bills.list_upcoming_bills(7)
    render(conn, :index, bills: bills)
  end
end
