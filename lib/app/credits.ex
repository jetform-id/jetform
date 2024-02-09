defmodule App.Credits do
  @moduledoc """
  The Credits context.
  """

  import Ecto.Query, warn: false
  alias App.Repo

  alias App.Credits.{Credit, Withdrawal}

  @doc """
  Returns the list of credits.

  ## Examples

      iex> list_credits()
      [%Credit{}, ...]

  """
  def list_credits do
    Repo.all(Credit)
  end

  def product_sold_this_month_by_user(user) do
    start_date = Timex.now() |> Timex.beginning_of_month()
    end_date = Timex.now() |> Timex.end_of_month()

    from(c in Credit,
      select: count(c.id),
      where: c.user_id == ^user.id,
      where: c.inserted_at >= ^start_date,
      where: c.inserted_at <= ^end_date
    )
    |> Repo.one()
    |> case do
      nil -> 0
      count -> count
    end
  end

  def nett_sales_this_month_by_user(user) do
    start_date = Timex.now() |> Timex.beginning_of_month()
    end_date = Timex.now() |> Timex.end_of_month()

    from(c in Credit,
      select: sum(c.user_amount),
      where: c.user_id == ^user.id,
      where: c.inserted_at >= ^start_date,
      where: c.inserted_at <= ^end_date
    )
    |> Repo.one()
    |> case do
      nil -> 0
      amount -> amount
    end
  end

  def withdrawable_credits_by_user(user, until \\ Timex.now()) do
    since =
      case get_last_successful_withdrawal_by_user(user) do
        nil -> ~U[2024-01-01 00:00:00Z]
        withdrawal -> withdrawal.withdrawal_timestamp
      end

    from(c in Credit,
      select: sum(c.user_amount),
      where: c.user_id == ^user.id,
      where: c.withdrawable_at <= ^until,
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

  # --------------- WITHDRAWALS ---------------

  def get_withdrawal!(id), do: Repo.get!(Withdrawal, id)
  def get_withdrawal(id), do: Repo.get(Withdrawal, id)

  def list_withdrawals_by_user!(user, query) do
    Withdrawal
    |> list_withdrawals_by_user_scope(user)
    |> Flop.validate_and_run!(query)
  end

  # admin don't see pending and cancelled withdrawals
  defp list_withdrawals_by_user_scope(q, %{role: :admin}),
    do: where(q, [w], w.status not in [:pending])

  # user see all withdrawals
  defp list_withdrawals_by_user_scope(q, user), do: where(q, user_id: ^user.id)

  def get_last_successful_withdrawal_by_user(user) do
    from(w in Withdrawal,
      where: w.user_id == ^user.id,
      where: w.status == :success,
      order_by: [desc: w.inserted_at]
    )
    |> Repo.one()
  end

  def get_unprocessed_withdrawal_by_user(user) do
    from(w in Withdrawal,
      where: w.user_id == ^user.id,
      where: w.status == :pending or w.status == :submitted
    )
    |> Repo.one()
  end

  def create_withdrawal(attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:withdrawal, create_withdrawal_changeset(attrs))
    |> Ecto.Multi.run(:notify, fn _repo, %{withdrawal: withdrawal} ->
      Workers.Withdrawal.notify(withdrawal)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{withdrawal: withdrawal}} ->
        {:ok, withdrawal}

      error ->
        error
    end
  end

  def update_withdrawal(
        %Withdrawal{status: old_status} = withdrawal,
        attrs
      ) do
    new_status = attrs["status"]
    status_changed = new_status != nil and new_status != Atom.to_string(old_status)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:withdrawal, Withdrawal.changeset(withdrawal, attrs))
    |> Ecto.Multi.run(:notify, fn _repo, %{withdrawal: withdrawal} ->
      if status_changed do
        Workers.Withdrawal.notify(withdrawal)
      else
        {:ok, :no_notify}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{withdrawal: withdrawal}} ->
        {:ok, withdrawal}

      error ->
        error
    end
  end

  def change_withdrawal(%Withdrawal{} = withdrawal, attrs \\ %{}) do
    Withdrawal.changeset(withdrawal, attrs)
  end

  def create_withdrawal_changeset(attrs) do
    Withdrawal.create_changeset(%Withdrawal{}, attrs)
  end

  def create_withdrawal_confirmation_token(withdrawal) do
    Phoenix.Token.sign(AppWeb.Endpoint, "withdrawal", withdrawal.id)
  end

  def verify_withdrawal_confirmation_token(token) do
    Phoenix.Token.verify(AppWeb.Endpoint, "withdrawal", token)
  end

  def withdrawal_attachment_url(withdrawal, opts \\ [signed: true]) do
    App.Credits.WithdrawalTransferProve.url(
      {withdrawal.admin_transfer_prove, withdrawal},
      :original,
      opts
    )
  end
end
