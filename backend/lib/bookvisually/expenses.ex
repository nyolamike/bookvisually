defmodule BookVisually.Expenses do
  @moduledoc """
  The Expenses context.
  Handles all business logic for managing expenses.
  """

  import Ecto.Query, warn: false
  alias BookVisually.Repo
  alias BookVisually.Expenses.Expense

  @doc """
  Returns the list of active expenses.
  """
  def list_expenses do
    Expense.active()
    |> Expense.order_by_date_desc()
    |> Repo.all()
  end

  @doc """
  Returns expenses for a specific resource.
  """
  def list_expenses_by_resource(resource_id) do
    Expense.active()
    |> Expense.by_resource(resource_id)
    |> Expense.order_by_date_desc()
    |> Repo.all()
  end

  @doc """
  Returns expenses within a date range.
  """
  def list_expenses_by_date_range(start_date, end_date) do
    Expense.active()
    |> Expense.by_date_range(start_date, end_date)
    |> Expense.order_by_date_desc()
    |> Repo.all()
  end

  @doc """
  Gets a single expense.
  """
  def get_expense!(id) do
    Expense.active()
    |> Repo.get!(id)
  end

  @doc """
  Gets a single expense, including deleted ones.
  """
  def get_expense_with_deleted!(id) do
    Expense.with_deleted()
    |> Repo.get!(id)
  end

  @doc """
  Creates an expense.
  """
  def create_expense(attrs \\ %{}) do
    %Expense{}
    |> Expense.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an expense.
  """
  def update_expense(%Expense{} = expense, attrs) do
    expense
    |> Expense.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Soft deletes an expense.
  """
  def soft_delete_expense(%Expense{} = expense) do
    expense
    |> Expense.soft_delete_changeset()
    |> Repo.update()
  end

  @doc """
  Restores a soft-deleted expense.
  """
  def restore_expense(%Expense{} = expense) do
    expense
    |> Expense.restore_changeset()
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking expense changes.
  """
  def change_expense(%Expense{} = expense, attrs \\ %{}) do
    Expense.changeset(expense, attrs)
  end

  @doc """
  Gets total expenses for a resource.
  """
  def get_total_for_resource(resource_id) do
    Expense.active()
    |> Expense.by_resource(resource_id)
    |> select([e], sum(e.total_amount))
    |> Repo.one()
    |> case do
      nil -> Decimal.new("0")
      total -> total
    end
  end

  @doc """
  Gets total expenses within a date range.
  """
  def get_total_for_date_range(start_date, end_date) do
    Expense.active()
    |> Expense.by_date_range(start_date, end_date)
    |> select([e], sum(e.total_amount))
    |> Repo.one()
    |> case do
      nil -> Decimal.new("0")
      total -> total
    end
  end
end
