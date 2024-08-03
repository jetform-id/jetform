defmodule App.PaymentGateway.Ipaymu do
  @behaviour App.PaymentGateway.Provider

  alias App.Repo
  alias App.Orders.{Order, Payment}
  alias App.PaymentGateway.{ProviderInfo, CreateTransactionResult, GetTransactionResult}

  @sandbox_base_url "https://sandbox.ipaymu.com"
  @production_base_url "https://my.ipaymu.com"

  @impl true
  def id(), do: "ipaymu"

  @impl true
  def info(), do: ProviderInfo.new("iPaymu", "https://ipaymu.com")

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

  @doc """
  ```elixir
  %{
    "Amount" => 50000,
    "BuyerEmail" => "seller@jetform.local",
    "BuyerName" => "Eka Putra",
    "BuyerPhone" => "081000000",
    "CreatedDate" => "2024-07-27 16:37:27",
    "ExpiredDate" => "2024-07-28 04:37:26",
    "Fee" => 4000,
    "IsLocked" => false,
    "Notes" => nil,
    "PaidStatus" => "unpaid",
    "PaymentChannel" => "bca",
    "PaymentCode" => "5634010000014021",
    "PaymentMethod" => "va",
    "PaymentName" => "OTTOPAY",
    "Receiver" => "JetForm",
    "ReferenceId" => "fecf5db1-a461-4db6-be9b-df9daccb0025",
    "RelatedId" => nil,
    "Sender" => "System",
    "SessionId" => "20f07c39-59fd-40e6-82e2-d2bbb1708f49",
    "SettlementDate" => nil,
    "Status" => 0,
    "StatusDesc" => "Menunggu Pembayaran",
    "SubTotal" => 50000,
    "SuccessDate" => nil,
    "TransactionId" => 139385,
    "Type" => 7,
    "TypeDesc" => "VA & Transfer Bank"
  }
  ```
  """
  @impl true
  def get_transaction(id) do
    payload = %{
      transactionId: id,
      account: config_value(:va)
    }

    signature = compute_signature("POST", payload)

    get_http_client(signature)
    |> Tesla.post("/api/v2/transaction", payload)
    |> case do
      {:ok,
       %Tesla.Env{
         status: 200,
         body: %{"Success" => true, "Data" => %{"Status" => status} = data}
       }} ->
        trx_status =
          case status do
            -2 -> "expire"
            0 -> "pending"
            1 -> "paid"
            2 -> "cancel"
            3 -> "refund"
            4 -> "error"
            5 -> "failure"
            # 6 -> paid but unsettled
            6 -> "paid"
            7 -> "escrow"
            _ -> "unknown"
          end

        result = %GetTransactionResult{
          payload: Jason.encode!(data),
          type: data["TypeDesc"],
          trx_id: data["TransactionId"] |> to_string(),
          trx_status: trx_status,
          status_code: to_string(status),
          gross_amount: data["Amount"],
          fee: data["Fee"]
        }

        {:ok, result}

      {_, %Tesla.Env{status: status, body: body}} ->
        {:error, %{"status" => status, "body" => body}}
    end
  end

  @impl true
  def cancel_transaction(_id), do: {:ok, :noop}

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

      error ->
        error
    end
  end

  @impl true
  def create_transaction_payload(%Order{} = order, %Payment{} = payment, _options \\ []) do
    order = Repo.preload(order, :product)

    payload = %{
      referenceId: payment.id,
      product: [order.product_name],
      description: [order.product_variant_name],
      qty: [1],
      price: [order.total],
      returnUrl: "#{AppWeb.Utils.base_url()}/api/payment/ipaymu/#{payment.id}/redirect",
      notifyUrl: "#{AppWeb.Utils.base_url()}/api/payment/ipaymu/#{payment.id}/notification",
      cancelUrl: "#{AppWeb.Utils.base_url()}/api/payment/ipaymu/#{payment.id}/redirect",
      buyerName: order.customer_name,
      buyerPhone: order.customer_phone,
      buyerEmail: order.customer_email
    }

    case config_value(:payment_method) do
      "auto" ->
        payload

      method ->
        Map.put(payload, "paymentMethod", method)
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

    adapter =
      case config_value(:use_proxy) do
        true -> {Tesla.Adapter.Finch, name: App.FinchWithProxy, receive_timeout: 30_000}
        false -> {Tesla.Adapter.Finch, name: App.Finch, receive_timeout: 30_000}
      end

    Tesla.client(middlewares, adapter)
  end
end

defmodule App.PaymentGateway.Ipaymu.Test do
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

  def get_transaction(id) do
    App.PaymentGateway.Ipaymu.get_transaction(id)
  end
end
