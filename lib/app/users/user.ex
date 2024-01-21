defmodule App.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  use Pow.Ecto.Schema

  use Pow.Extension.Ecto.Schema,
    extensions: [PowResetPassword, PowEmailConfirmation]

  # alias App.Utils.ReservedWords

  @default_tz "Asia/Jakarta"
  @tz_labels [
    {"Asia/Jakarta", "WIB", "Waktu Indonesia Barat"},
    {"Asia/Makassar", "WITA", "Waktu Indonesia Tengah"},
    {"Asia/Jayapura", "WIT", "Waktu Indonesia Timur"}
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    pow_user_fields()

    # field :username, :string
    field :timezone, :string, default: @default_tz
    field :plan, :string
    field :plan_valid_until, :utc_datetime

    # Since we're using Pow's controller, here we define a :action virtual field
    # so that we can control the changeset behaviour based on :action value.
    field :action, :string, virtual: true

    has_one :bank_account, App.Users.BankAccount
    has_many :products, App.Products.Product
    has_many :orders, App.Orders.Order
    has_many :credits, App.Credits.Credit
    has_many :withdrawals, App.Credits.Withdrawal

    timestamps(type: :utc_datetime)
  end

  def tz_select_options() do
    Enum.map(@tz_labels, fn {tz, label, desc} ->
      {"#{desc} (#{label})", tz}
    end)
  end

  def tz_label(tz) do
    Enum.find(@tz_labels, fn {tz_, _, _} -> tz_ == tz end) |> elem(1)
  end

  def changeset(user_or_changeset, %{"action" => "create"} = attrs) do
    # on create: we assigns user default plan.
    default_plan = Application.get_env(:app, :default_plan)

    attrs =
      attrs
      |> Map.put("plan", default_plan.id())
      |> Map.put("plan_valid_until", default_plan.valid_until(Timex.now()))

    user_or_changeset
    |> pow_changeset(attrs)
    |> pow_extension_changeset(attrs)
    |> cast(attrs, [:timezone, :plan, :plan_valid_until])
  end

  def changeset(user_or_changeset, %{"action" => "update"} = attrs) do
    # on update: we only allow user to update their email, password, and timezone.
    user_or_changeset
    |> pow_changeset(attrs)
    |> pow_extension_changeset(attrs)
    |> cast(attrs, [:timezone])
  end

  def changeset(user_or_changeset, attrs) do
    # else: changeset for Pow's fields.
    user_or_changeset
    |> pow_changeset(attrs)
    |> pow_extension_changeset(attrs)
  end

  # defp validate_username(changeset) do
  #   changeset
  #   |> validate_required([:username])
  #   |> validate_length(:username, min: 4, max: 20)
  #   |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/)
  #   |> validate_reserved_words(:username)
  #   |> unsafe_validate_unique(:username, App.Repo)
  #   |> unique_constraint(:username)
  # end

  # defp validate_reserved_words(changeset, field) do
  #   validate_change(changeset, field, fn _, value ->
  #     if ReservedWords.is_reserved?(value) do
  #       [{field, "is reserved"}]
  #     else
  #       []
  #     end
  #   end)
  # end
end
