defmodule App.Orders.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :provider,
    :create_transaction_response,
    :get_transaction_response,
    :notification_payload,
    :type,
    :trx_id,
    :trx_status,
    :fraud_status,
    :status_code,
    :gross_amount,
    :redirect_url,
    :fee,
    :cancellation_reason
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "order_payments" do
    field :provider, :string
    field :create_transaction_response, :map
    field :get_transaction_response, :map
    field :notification_payload, :map
    field :type, :string
    field :trx_id, :string
    field :trx_status, :string
    field :fraud_status, :string
    field :status_code, :string
    field :gross_amount, :float
    field :redirect_url, :string
    # payment gateway fee
    field :fee, :integer
    field :cancellation_reason, :string

    belongs_to :order, App.Orders.Order
    has_many :notifications, App.Orders.PaymentNotification

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
