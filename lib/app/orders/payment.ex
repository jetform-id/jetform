defmodule App.Orders.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :payload,
    :type,
    :trx_id,
    :trx_status,
    :fraud_status,
    :status_code,
    :gross_amount,
    :redirect_url
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "order_payments" do
    field :payload, :string
    field :type, :string
    field :trx_id, :string
    field :trx_status, :string
    field :fraud_status, :string
    field :status_code, :string
    field :gross_amount, :float
    field :redirect_url, :string

    belongs_to :order, App.Orders.Order

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(payment, attrs) do
    cast(payment, attrs, @fields)
  end

  def create_changeset(payment, attrs) do
    payment
    |> changeset(attrs)
    |> validate_order(attrs)
  end

  defp validate_order(changeset, attrs) do
    case Map.get(attrs, "order") do
      nil -> add_error(changeset, :order, "can't be blank")
      order -> put_assoc(changeset, :order, order)
    end
  end
end
