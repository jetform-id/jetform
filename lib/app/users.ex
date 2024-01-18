defmodule App.Users do
  import Ecto.Query, warn: false

  alias App.Repo
  alias App.Users.{User, BankAccount}
  alias App.Orders.Order
  alias App.Credits.Credit

  defdelegate tz_select_options(), to: User
  defdelegate tz_label(tz), to: User

  def get_bank_account_by_user(user) do
    case Repo.get_by(BankAccount, user_id: user.id) do
      nil -> {:error, :not_found}
      bank_account -> {:ok, bank_account}
    end
  end

  def change_bank_account(bank_account, attrs) do
    bank_account |> BankAccount.changeset(attrs)
  end

  def create_bank_account(attrs) do
    %BankAccount{}
    |> BankAccount.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_bank_account(bank_account, attrs) do
    bank_account
    |> BankAccount.changeset(attrs)
    |> Repo.update()
  end

  def product_sold_this_month(user) do
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

  def gross_sales_this_month(user) do
    start_date = Timex.now() |> Timex.beginning_of_month()
    end_date = Timex.now() |> Timex.end_of_month()

    from(o in Order,
      select: sum(o.total),
      where: o.user_id == ^user.id,
      where: o.inserted_at >= ^start_date,
      where: o.inserted_at <= ^end_date
    )
    |> Repo.one()
    |> case do
      nil -> 0
      amount -> amount
    end
  end

  def nett_sales_this_month(user) do
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

  def withdrawable_credits(user, nil) do
    withdrawable_credits(user, ~U[2024-01-01 00:00:00Z])
  end

  def withdrawable_credits(user, since) do
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

  def pending_credits(user) do
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
end
