defmodule BookVisually.Bills do
  @moduledoc """
  The Bills context.
  Handles all business logic for managing utility bills.
  """

  import Ecto.Query, warn: false
  alias BookVisually.Repo
  alias BookVisually.Bills.UtilityBill

  @doc """
  Returns the list of active bills.
  """
  def list_bills do
    UtilityBill.active()
    |> UtilityBill.order_by_due_date()
    |> Repo.all()
  end

  @doc """
  Returns bills for a specific resource.
  """
  def list_bills_by_resource(resource_id) do
    UtilityBill.active()
    |> UtilityBill.by_resource(resource_id)
    |> UtilityBill.order_by_due_date()
    |> Repo.all()
  end

  @doc """
  Returns bills by status.
  """
  def list_bills_by_status(status) do
    UtilityBill.active()
    |> UtilityBill.by_status(status)
    |> UtilityBill.order_by_due_date()
    |> Repo.all()
  end

  @doc """
  Returns unpaid bills (unpaid or partially_paid).
  """
  def list_unpaid_bills do
    UtilityBill.active()
    |> UtilityBill.unpaid()
    |> UtilityBill.order_by_due_date()
    |> Repo.all()
  end

  @doc """
  Returns overdue bills.
  """
  def list_overdue_bills do
    UtilityBill.active()
    |> UtilityBill.overdue()
    |> UtilityBill.order_by_due_date()
    |> Repo.all()
  end

  @doc """
  Gets a single bill.
  """
  def get_bill!(id) do
    UtilityBill.active()
    |> Repo.get!(id)
  end

  @doc """
  Gets a single bill, including deleted ones.
  """
  def get_bill_with_deleted!(id) do
    UtilityBill.with_deleted()
    |> Repo.get!(id)
  end

  @doc """
  Creates a bill.
  """
  def create_bill(attrs \\ %{}) do
    %UtilityBill{}
    |> UtilityBill.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a bill.
  """
  def update_bill(%UtilityBill{} = bill, attrs) do
    bill
    |> UtilityBill.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Soft deletes a bill.
  """
  def soft_delete_bill(%UtilityBill{} = bill) do
    bill
    |> UtilityBill.soft_delete_changeset()
    |> Repo.update()
  end

  @doc """
  Restores a soft-deleted bill.
  """
  def restore_bill(%UtilityBill{} = bill) do
    bill
    |> UtilityBill.restore_changeset()
    |> Repo.update()
  end

  @doc """
  Marks a bill as paid.
  """
  def mark_as_paid(%UtilityBill{} = bill) do
    bill
    |> UtilityBill.update_status_changeset("paid")
    |> Repo.update()
  end

  @doc """
  Marks a bill as partially paid.
  """
  def mark_as_partially_paid(%UtilityBill{} = bill) do
    bill
    |> UtilityBill.update_status_changeset("partially_paid")
    |> Repo.update()
  end

  @doc """
  Marks a bill as overdue.
  """
  def mark_as_overdue(%UtilityBill{} = bill) do
    bill
    |> UtilityBill.update_status_changeset("overdue")
    |> Repo.update()
  end

  @doc """
  Cancels a bill.
  """
  def cancel_bill(%UtilityBill{} = bill) do
    bill
    |> UtilityBill.update_status_changeset("cancelled")
    |> Repo.update()
  end

  @doc """
  Gets total unpaid amount across all unpaid bills.
  """
  def get_total_unpaid do
    UtilityBill.active()
    |> UtilityBill.unpaid()
    |> select([b], sum(b.total_amount))
    |> Repo.one()
    |> case do
      nil -> Decimal.new("0")
      total -> total
    end
  end

  @doc """
  Gets total unpaid amount for a specific resource.
  """
  def get_total_unpaid_for_resource(resource_id) do
    UtilityBill.active()
    |> UtilityBill.by_resource(resource_id)
    |> UtilityBill.unpaid()
    |> select([b], sum(b.total_amount))
    |> Repo.one()
    |> case do
      nil -> Decimal.new("0")
      total -> total
    end
  end

  @doc """
  Marks bills as overdue if past due date.
  """
  def mark_overdue_bills do
    today = Date.utc_today()

    UtilityBill.active()
    |> UtilityBill.unpaid()
    |> where([b], b.due_date < ^today)
    |> Repo.all()
    |> Enum.each(&mark_as_overdue/1)
  end

  @doc """
  Returns bills due within the next N days.
  """
  def list_upcoming_bills(days \\ 7) do
    today = Date.utc_today()
    future_date = Date.add(today, days)

    UtilityBill.active()
    |> UtilityBill.unpaid()
    |> where([b], b.due_date >= ^today and b.due_date <= ^future_date)
    |> UtilityBill.order_by_due_date()
    |> Repo.all()
  end
end
