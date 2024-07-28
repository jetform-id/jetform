defmodule App.Credits.Credit do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(user_amount system_amount gateway_amount withdrawable_at)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "credits" do
    # - user_amount is the nett amount that user will receive
    # - system_amount is gross amount that system will receive (service fee)
    # we put them in the same record so we can easily calculate the amount for both user and system.
    field :user_amount, :integer
    field :system_amount, :integer
    field :gateway_amount, :integer
    field :withdrawable_at, :utc_datetime

    belongs_to :user, App.Users.User
    belongs_to :order, App.Orders.Order

    timestamps(type: :utc_datetime)
  end

  @doc """
  Based on https://support.midtrans.com/hc/id/articles/204189734-Kapan-Saya-menerima-dana-transaksi-dari-Midtrans-
  Funds are withdrawable 3 working days (excluding weekend) after the order is paid (settlement).

  Time table:
  Op = order paid
  Cp = credit pending
  CR = credit ready to withdraw (at time 00:00:00)
  ~  = weekend
  ----------------------------------------------------------------------------------------
  Monday | Tuesday | Wednesday | Thursday | Friday | Saturday | Sunday | Monday | Tuesday
  ----------------------------------------------------------------------------------------
  OP     | CP      | CP        | CP       | CR     | ~        | ~      |         |
         | OP      | CP        | CP       | CP     | ~        | ~      | CR      |
         |         | OP        | CP       | CP     | ~        | ~      | CP      | CR
  ----------------------------------------------------------------------------------------
  """
  def withdrawable_at(paid_at) do
    shift_day(paid_at, 3) |> Timex.beginning_of_day()
  end

  @doc false
  def changeset(credit, attrs) do
    credit
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end

  def create_changeset(credit, attrs) do
    credit
    |> changeset(attrs)
    |> validate_order(attrs)
  end

  defp validate_order(changeset, attrs) do
    case Map.get(attrs, "order") do
      nil ->
        add_error(changeset, :order, "can't be blank")

      order ->
        order = App.Repo.preload(order, :user)
        put_assoc(changeset, :order, order) |> put_assoc(:user, order.user)
    end
  end

  defp shift_day(today, days) do
    # recursively shifting day into target day by skipping weekend
    weekend = [6, 7]
    tomorrow = Timex.shift(today, days: 1)
    tomorrow_wd = Timex.weekday(tomorrow)

    cond do
      days == 0 ->
        tomorrow

      tomorrow_wd in weekend ->
        shift_day(Timex.shift(today, days: 1), days)

      true ->
        shift_day(Timex.shift(today, days: 1), days - 1)
    end
  end
end
