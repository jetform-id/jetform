defmodule App.PaymentGateway.Ipaymu do
  @behaviour App.PaymentGateway.Provider

  alias App.Repo
  alias App.Orders.{Order, Payment}
  alias App.PaymentGateway.CreateTransactionResult

  @sandbox_base_url "https://sandbox.ipaymu.com"
  @production_base_url "https://my.ipaymu.com"

  @impl true
  def name(), do: "ipaymu"

  @impl true
  def config_value(key) when is_atom(key) do
    case Application.get_env(:app, :ipaymu)[key] do
      nil -> raise "Missing config :app, :ipaymu, :#{key}"
      value -> value
    end
  end

  def config_value(key) when is_binary(key) do
    config_value(String.to_atom(key))
  end

  @impl true
  def create_transaction(%{} = payload) do
    signature = compute_signature("POST", payload)

    get_http_client(signature)
    |> Tesla.post("/api/v2/payment", payload)
    |> case do
      {:ok,
       %Tesla.Env{
         status: 200,
         body: %{"Success" => true, "Data" => %{"SessionID" => sess_id, "Url" => url}}
       }} ->
        {:ok, CreateTransactionResult.new(sess_id, url)}

      {_, %Tesla.Env{status: status, body: body}} ->
        {:error, %{"status" => status, "body" => body}}
    end
  end

  @impl true
  def get_transaction(_id), do: {:ok, %{}}

  @impl true
  def cancel_transaction(_id), do: {:ok, :noop}

  @impl true
  def create_transaction_payload(%Order{} = order, %Payment{} = payment, options \\ []) do
    order = Repo.preload(order, :product)
    expiry_in_minutes = Keyword.get(options, :expiry_in_minutes, 30)

    %{
      "transaction_details" => %{
        "order_id" => payment.id,
        "gross_amount" => order.total
      },
      "item_details" => [
        %{
          "id" => order.product_id,
          "price" => order.total,
          "quantity" => 1,
          "name" => order.product_name,
          "brand" => order.product_variant_name
        }
      ],
      "customer_details" => %{
        "first_name" => order.customer_name,
        "email" => order.customer_email
      },
      "expiry" => %{
        "unit" => "minutes",
        "duration" => expiry_in_minutes
      },
      "page_expiry" => %{
        "duration" => expiry_in_minutes,
        "unit" => "minutes"
      },
      "enabled_payments" => config_value(:enabled_payments),
      "custom_field1" => order.product.user_id
    }
  end

  def create_direct_payment_qris(%{} = payload) do
    payload =
      payload
      |> Map.put("paymentMethod", "qris")
      |> Map.put("paymentChannel", "qris")

    signature = compute_signature("POST", payload)

    get_http_client(signature)
    |> Tesla.post("/api/v2/payment/direct", payload)
    |> case do
      {:ok,
       %Tesla.Env{
         status: 200,
         body:
           %{
             "Success" => true,
             "Data" => %{"TransactionId" => trx_id, "Fee" => fee, "QrImage" => qr_image}
           } = body
       }} ->
        {:ok, %{channel: "QRIS", trx_id: to_string(trx_id), qr_image: qr_image, fee: fee}, body}

      {_, %Tesla.Env{status: status, body: body}} ->
        {:error, %{"status" => status, "body" => body}}
    end
  end

  @doc """
  Based on:
  https://storage.googleapis.com/ipaymu-docs/ipaymu-api/iPaymu-signature-documentation-v2.pdf
  """
  def compute_signature(method, %{} = payload) do
    va = config_value(:va)
    api_key = config_value(:api_key)

    encrypted_payload =
      :crypto.hash(
        :sha256,
        Jason.encode!(payload)
      )
      |> Base.encode16()
      |> String.downcase()

    string_to_sign = "#{method}:#{va}:#{encrypted_payload}:#{api_key}"

    :crypto.mac(:hmac, :sha256, api_key, string_to_sign)
    |> Base.encode16()
    |> String.downcase()
  end

  defp get_http_client(signature) do
    timestamp = Timex.now() |> Timex.format!("%Y%m%d%H%M%S", :strftime)

    base_url =
      if config_value(:mode) == "production", do: @production_base_url, else: @sandbox_base_url

    headers = [
      {"accept", "application/json"},
      {"content-type", "application/json"},
      {"signature", signature},
      {"va", config_value(:va)},
      {"timestamp", timestamp}
    ]

    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, headers}
    ]

    Tesla.client(middlewares)
  end
end

defmodule App.PaymentGateway.Ipaymu.Test do
  def direct_payment_qris do
    payload = %{
      referenceId: "testRefId",
      product: ["JetForm Test Product"],
      qty: [1],
      price: [100_000],
      amount: 100_000,
      description: ["JetForm Test Product Description"],
      notifyUrl: "http://localhost:4000/notify",
      name: "John Doe",
      phone: "081234567890",
      email: "support@jetform.local"
    }

    App.PaymentGateway.Ipaymu.create_direct_payment_qris(payload)
  end

  def create_transaction do
    payload = %{
      referenceId: "testRefId",
      product: ["JetForm Test Product"],
      qty: [1],
      price: [100_000],
      description: ["JetForm Test Product Description"],
      returnUrl: "http://localhost:4000/return",
      notifyUrl: "http://localhost:4000/notify",
      cancelUrl: "http://localhost:4000/cancel",
      buyerName: "John Doe",
      buyerPhone: "081234567890",
      buyerEmail: "support@jetform.local"
      # paymentMethod: "qris"
    }

    App.PaymentGateway.Ipaymu.create_transaction(payload)
  end
end
