defmodule App.Credits do
  @moduledoc """
  The Credits context.
  """

  import Ecto.Query, warn: false
  alias App.Repo

  alias App.Credits.Credit

  @doc """
  Returns the list of credits.

  ## Examples

      iex> list_credits()
      [%Credit{}, ...]

  """
  def list_credits do
    Repo.all(Credit)
  end

  def withdrawable_credits_by_user(user, nil) do
    withdrawable_credits_by_user(user, ~U[2024-01-01 00:00:00Z])
  end

  def withdrawable_credits_by_user(user, since) do
    from(c in Credit,
      select: sum(c.user_amount),
      where: c.user_id == ^user.id,
      where: c.withdrawable_at <= ^Timex.now(),
      where: c.withdrawable_at > ^since
    )
    |> Repo.one()
    |> case do
      nil -> 0
      amount -> amount
    end
  end

  def pending_credits_by_user(user) do
    from(c in Credit,
      select: sum(c.user_amount),
      where: c.user_id == ^user.id,
      where: c.withdrawable_at > ^Timex.now()
    )
    |> Repo.one()
    |> case do
      nil -> 0
      amount -> amount
    end
  end

  @doc """
  Gets a single credit.

  Raises `Ecto.NoResultsError` if the Credit does not exist.

  ## Examples

      iex> get_credit!(123)
      %Credit{}

      iex> get_credit!(456)
      ** (Ecto.NoResultsError)

  """
  def get_credit!(id), do: Repo.get!(Credit, id)

  @doc """
  Creates a credit.

  ## Examples

      iex> create_credit(%{field: value})
      {:ok, %Credit{}}

      iex> create_credit(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_credit(order) do
    create_changeset_for_order(order) |> Repo.insert()
  end

  @doc """
  Updates a credit.

  ## Examples

      iex> update_credit(credit, %{field: new_value})
      {:ok, %Credit{}}

      iex> update_credit(credit, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_credit(%Credit{} = credit, attrs) do
    credit
    |> Credit.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a credit.

  ## Examples

      iex> delete_credit(credit)
      {:ok, %Credit{}}

      iex> delete_credit(credit)
      {:error, %Ecto.Changeset{}}

  """
  def delete_credit(%Credit{} = credit) do
    Repo.delete(credit)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking credit changes.

  ## Examples

      iex> change_credit(credit)
      %Ecto.Changeset{data: %Credit{}}

  """
  def change_credit(%Credit{} = credit, attrs \\ %{}) do
    Credit.changeset(credit, attrs)
  end

  def create_changeset_for_order(order) do
    %Credit{}
    |> Credit.create_changeset(%{
      "order" => order,
      "user_amount" => order.total - order.service_fee,
      "system_amount" => order.service_fee,
      "withdrawable_at" => Credit.withdrawable_at(order.paid_at)
    })
  end

  def backfill_orders_credit(orders) do
    Enum.map(orders, &create_credit/1)
  end
end
