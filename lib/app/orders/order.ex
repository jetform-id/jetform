defmodule App.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:status, :product_id, :product_variant_id, :inserted_at],
    sortable: [:inserted_at]
  }

  @mail_regex ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
  @required_fields ~w(invoice_number valid_until customer_name customer_email sub_total total)a
  @optional_fields ~w(customer_phone status discount_name discount_value service_fee payment_type gateway_fee paid_at cancellation_reason)a
  @statuses ~w(pending paid expired cancelled free)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "orders" do
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :invoice_number, :string
    field :valid_until, :utc_datetime
    field :customer_name, :string
    field :customer_email, :string
    field :customer_phone, :string
    field :product_name, :string
    field :product_variant_name, :string
    field :discount_name, :string
    field :discount_value, :integer
    field :sub_total, :integer
    field :total, :integer
    field :payment_type, :string
    field :paid_at, :utc_datetime
    field :service_fee, :integer
    field :gateway_fee, :integer
    field :cancellation_reason, :string

    belongs_to :user, App.Users.User
    belongs_to :product, App.Products.Product
    belongs_to :product_variant, App.Products.Variant
    has_many :payments, App.Orders.Payment
    has_many :credits, App.Credits.Credit
    has_one :access, App.Contents.Access

    many_to_many :contents, App.Contents.Content,
      join_through: App.Orders.OrderContent,
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def time_before_expired(order) do
    case Timex.compare(Timex.now(), order.valid_until, :second) do
      -1 -> Timex.diff(order.valid_until, Timex.now(), :second)
      0 -> 0
      1 -> 0
    end
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def create_changeset(order, attrs) do
    order
    |> changeset(attrs)
    |> validate_format(:customer_email, @mail_regex)
    |> put_user(attrs)
    |> put_product(attrs)
    |> put_product_variant(attrs)
    |> put_status()
  end

  def put_contents(changeset, contents) do
    put_assoc(changeset, :contents, contents)
  end

  defp put_user(changeset, attrs) do
    case Map.get(attrs, "user") do
      nil ->
        add_error(changeset, :user, "can't be blank")

      user ->
        put_assoc(changeset, :user, user)
    end
  end

  defp put_product(changeset, attrs) do
    case Map.get(attrs, "product") do
      nil ->
        add_error(changeset, :product, "can't be blank")

      product ->
        changeset
        |> put_assoc(:product, product)
        |> put_change(:product_name, product.name)
    end
  end

  defp put_product_variant(changeset, attrs) do
    case Map.get(attrs, "product_variant") do
      nil ->
        changeset

      variant ->
        changeset
        |> put_assoc(:product_variant, variant)
        |> put_change(:product_variant_name, variant.name)
    end
  end

  defp put_status(changeset) do
    case fetch_field!(changeset, :total) do
      0 ->
        put_change(changeset, :status, :free)

      _ ->
        changeset
    end
  end
end
