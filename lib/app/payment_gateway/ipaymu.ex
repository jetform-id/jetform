defmodule App.PaymentGateway.Ipaymu do
  @sandbox_base_url "https://sandbox.ipaymu.com"
  @production_base_url "https://my.ipaymu.com"

  def create_redirect_payment(%{} = payload) do
    signature = compute_signature("POST", payload)

    get_http_client(signature)
    |> Tesla.post("/api/v2/payment", payload)
    |> case do
      {:ok,
       %Tesla.Env{
         status: 200,
         body: %{"Success" => true, "Data" => %{"SessionID" => sess_id, "Url" => url}} = body
       }} ->
        {:ok, %{trx_id: sess_id, payment_url: url}, body}

      {_, %Tesla.Env{status: status, body: body}} ->
        {:error, %{"status" => status, "body" => body}}
    end
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
    va = config(:va)
    api_key = config(:api_key)

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
    base_url = if config(:mode) == "production", do: @production_base_url, else: @sandbox_base_url

    headers = [
      {"accept", "application/json"},
      {"content-type", "application/json"},
      {"signature", signature},
      {"va", config(:va)},
      {"timestamp", timestamp}
    ]

    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, headers}
    ]

    Tesla.client(middlewares)
  end

  defp config(key) do
    Application.fetch_env!(:app, :ipaymu)[key]
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

  def redirect_payment do
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
      buyerEmail: "support@jetform.local",
      paymentMethod: "qris"
    }

    App.PaymentGateway.Ipaymu.create_redirect_payment(payload)
  end
end
