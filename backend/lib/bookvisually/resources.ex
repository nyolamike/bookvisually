defmodule BookVisually.Resources do
  @moduledoc """
  The Resources context.
  Handles all business logic for managing resources (subscriptions, utilities, supplies, assets).
  """

  import Ecto.Query, warn: false
  alias BookVisually.Repo
  alias BookVisually.Resources.Resource

  @doc """
  Returns the list of active resources.

  ## Examples

      iex> list_resources()
      [%Resource{}, ...]

  """
  def list_resources do
    Resource.active()
    |> Repo.all()
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
end
