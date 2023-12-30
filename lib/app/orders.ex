defmodule App.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false
  alias App.Repo
  alias Repo

  alias App.Orders.Order
  alias App.Contents

  defdelegate status(order), to: Order
  defdelegate time_before_expired(order), to: Order

  def generate_invoice_number() do
    month = Timex.now() |> Timex.format!("%y%m%d", :strftime)
    random = :crypto.strong_rand_bytes(2) |> :crypto.bytes_to_integer()
    "#{month}-#{random}"
  end

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders()
      [%Order{}, ...]

  """
  def list_orders do
    Repo.all(Order)
  end

  @doc """
  Returns the list of orders for a given user.
  """
  def list_orders!(user, params) do
    Order
    |> where(user_id: ^user.id)
    |> Flop.validate_and_run!(params)
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

      iex> get_order!(123)
      %Order{}

      iex> get_order!(456)
      ** (Ecto.NoResultsError)

  """
  def get_order!(id), do: Repo.get!(Order, id)

  @doc """
  Creates a order.

  ## Examples

      iex> create_order(%{field: value})
      {:ok, %Order{}}

      iex> create_order(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order(attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:order, Order.create_changeset(%Order{}, attrs))
    |> Ecto.Multi.run(:contents, fn repo, %{order: order} ->
      # get contents for order
      order = repo.preload(order, :product_variant)

      case order.product_variant do
        nil ->
          {:ok, Contents.list_contents_by_product(order.product)}

        variant ->
          {:ok, Contents.list_contents_by_variant(variant)}
      end
    end)
    |> Ecto.Multi.update(:order_contents, fn %{order: order, contents: contents} ->
      # put contents to order
      Repo.preload(order, :contents)
      |> Order.changeset(%{})
      |> Order.put_contents(contents)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{order_contents: order}} ->
        {:ok, order}

      {:error, _op, _value, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a order.

  ## Examples

      iex> update_order(order, %{field: new_value})
      {:ok, %Order{}}

      iex> update_order(order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a order.

  ## Examples

      iex> delete_order(order)
      {:ok, %Order{}}

      iex> delete_order(order)
      {:error, %Ecto.Changeset{}}

  """
  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(order)
      %Ecto.Changeset{data: %Order{}}

  """
  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  def valid_until_hours(hour \\ 1) do
    DateTime.utc_now() |> DateTime.add(hour, :hour)
  end
end
