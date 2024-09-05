defmodule App.Orders.PaymentNotification do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :provider,
    :body_params,
    :path_params,
    :query_params,
    :req_headers,
    :req_cookies,
    :request_path,
    :request_method,
    :remote_ip,
    :host,
    :port
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "order_payment_notifications" do
    field :provider, :string
    field :body_params, :map
    field :path_params, :map
    field :query_params, :map
    field :req_headers, :map
    field :req_cookies, :map
    field :request_path, :string
    field :request_method, :string
    field :remote_ip, :string
    field :host, :string
    field :port, :integer
    belongs_to :payment, App.Orders.Payment, foreign_key: :payment_id
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(payment, attrs) do
    cast(payment, attrs, @fields)
  end

  @doc false
  def changeset_from_conn(%Plug.Conn{} = conn, payment \\ %App.Orders.Payment{}) do
    remote_ip =
      case conn.remote_ip do
        {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
        ip -> inspect(ip)
      end

    attrs = %{
      provider: payment.provider,
      body_params: conn.body_params,
      path_params: conn.path_params,
      query_params: conn.query_params,
      req_headers: conn.req_headers |> Enum.into(%{}),
      req_cookies: conn.req_cookies,
      request_path: conn.request_path,
      request_method: conn.method,
      remote_ip: remote_ip,
      host: conn.host,
      port: conn.port
    }

    cs = changeset(%__MODULE__{}, attrs)

    cond do
      payment.id -> put_assoc(cs, :payment, payment)
      true -> cs
    end
  end
end
