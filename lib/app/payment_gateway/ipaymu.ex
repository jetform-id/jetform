defmodule App.PaymentGateway.Ipaymu do
  @behaviour App.PaymentGateway.Provider

  alias App.Orders.{Order, Payment}

  alias App.PaymentGateway.{
    ProviderInfo,
    CreateTransactionResult,
    GetTransactionResult,
    PaymentChannel,
    PaymentChannelCategory
  }

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

  @impl true
  def list_channels() do
    signature = compute_signature("GET")

    get_http_client(signature)
    |> Tesla.get("/api/v2/payment-channels")
    |> case do
      {:ok,
       %{
         status: 200,
         body: %{"Success" => true, "Data" => data}
       }} ->
        clean_channels(data)

      {_, %{status: status, body: body}} ->
        {:error, %{"status" => status, "body" => body}}

      error ->
        error
    end
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
       %{
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
          data: data,
          type: data["TypeDesc"],
          id: data["TransactionId"] |> to_string(),
          status: trx_status,
          status_code: to_string(status),
          gross_amount: data["Amount"],
          fee: data["Fee"]
        }

        {:ok, result}

      {_, %{status: status, body: body}} ->
        {:error, %{"status" => status, "body" => body}}
    end
  end

  @impl true
  def cancel_transaction(_id), do: {:ok, :noop}

  @impl true
  def create_redirect_transaction(%{} = payload) do
    signature = compute_signature("POST", payload)

    get_http_client(signature)
    |> Tesla.post("/api/v2/payment", payload)
    |> case do
      {:ok,
       %{
         status: 200,
         body: %{"Success" => true, "Data" => %{"SessionID" => sess_id, "Url" => url} = data}
       }} ->
        {:ok, CreateTransactionResult.new(sess_id, url, data)}

      {_, %{status: status, body: body}} ->
        {:error, %{"status" => status, "body" => body}}

      error ->
        error
    end
  end

  @impl true
  def create_redirect_transaction_payload(%Order{} = order, %Payment{} = payment, options \\ []) do
    global_payment_channel = config_value(:payment_channel)
    payment_channel = Keyword.get(options, :payment_channel)
    # default 2h
    expired = trunc(Keyword.get(options, :expiry_in_minutes, 120) / 60)

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
      buyerEmail: order.customer_email,
      expired: expired
    }

    cond do
      payment_channel != nil ->
        # in case payment_channel in "method:channel" format
        [method | _] = String.split(payment_channel, ":")
        Map.put(payload, "paymentMethod", method)

      global_payment_channel != "auto" ->
        Map.put(payload, "paymentMethod", global_payment_channel)

      true ->
        payload
    end
  end

  @impl true
  def create_direct_transaction(%{expired: expired_hr} = payload) do
    signature = compute_signature("POST", payload)

    get_http_client(signature)
    |> Tesla.post("/api/v2/payment/direct", payload)
    |> case do
      {:ok, %{status: 200, body: %{"Success" => true, "Data" => data}}} ->
        payment_id = data["ReferenceId"]
        trx_id = data["TransactionId"] |> to_string()

        payload = %{
          provider: id(),
          method: data["Via"] |> String.downcase(),
          channel: data["Channel"] |> String.downcase(),
          name: data["PaymentName"],
          number: data["PaymentNo"],
          qr_url: data["QrImage"],
          amount: data["Total"],
          trx_id: trx_id,
          expired: data["Expired"],
          token_expired_at: Timex.now() |> Timex.shift(hours: expired_hr)
        }

        max_age = expired_hr * 60 * 60
        token = Phoenix.Token.sign(AppWeb.Endpoint, "payment", payload, max_age: max_age)
        url = "#{AppWeb.Utils.base_url()}/payments/#{payment_id}?token=#{token}"
        {:ok, CreateTransactionResult.new(trx_id, url, data)}

      {_, %{status: status, body: body}} ->
        {:error, %{"status" => status, "body" => body}}

      error ->
        error
    end
  end

  @impl true
  def create_direct_transaction_payload(%Order{} = order, %Payment{} = payment, options \\ []) do
    [method, channel] =
      Keyword.get(options, :payment_channel, "qris:mpm") |> String.split(":")

    # default 2h
    expired = trunc(Keyword.get(options, :expiry_in_minutes, 120) / 60)

    %{
      name: order.customer_name,
      phone: order.customer_phone,
      email: order.customer_email,
      amount: order.total,
      notifyUrl: "#{AppWeb.Utils.base_url()}/api/payment/ipaymu/#{payment.id}/notification",
      comments: App.Orders.product_fullname(order),
      referenceId: payment.id,
      expired: expired,
      paymentMethod: method,
      paymentChannel: channel,
      feeDirection: Keyword.get(options, :fee_direction, "MERCHANT"),
      escrow: Keyword.get(options, :escrow, 0)
    }
  end

  @doc """
  Based on:
  https://storage.googleapis.com/ipaymu-docs/ipaymu-api/iPaymu-signature-documentation-v2.pdf
  """
  def compute_signature(method, %{} = payload \\ %{}) do
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

  def filter_channels([], _options), do: []

  def filter_channels([_ | _] = channels, options) do
    # - only can be a mix of category and category-channel: ["cc", "qris", "va:bri", "va:bni"]
    only = Keyword.get(options, :only, [])

    # build the filters
    {cat_filters, chan_filters} =
      Enum.reduce(only, {[], %{}}, fn x, {category, channel} ->
        case String.split(x, ":") do
          [cat, cha] ->
            {[cat | category], Map.put(channel, cat, Map.get(channel, cat, []) ++ [cha])}

          [cat] ->
            {[cat | category], channel}
        end
      end)

    filter_cat? = not Enum.empty?(cat_filters)

    channels
    |> Enum.filter(fn cat ->
      # filter the categories
      if filter_cat?, do: Enum.member?(cat_filters, cat.code), else: true
    end)
    |> Enum.map(fn cat ->
      # filter the channels in the category
      filter_chan? = Map.has_key?(chan_filters, cat.code)

      chans =
        cat.channels
        |> Enum.filter(fn chan ->
          if filter_chan?, do: Enum.member?(chan_filters[cat.code], chan.code), else: true
        end)

      %{cat | channels: chans}
    end)
  end

  defp clean_channels(channels) do
    channels
    |> Enum.filter(&Map.has_key?(&1, "Channels"))
    |> Enum.map(&clean_category/1)
  end

  defp clean_category(%{"Code" => code, "Name" => name, "Channels" => channels}) do
    channels =
      channels
      |> Enum.filter(&(Map.fetch!(&1, "FeatureStatus") == "active"))
      |> Enum.filter(&(Map.fetch!(&1, "HealthStatus") == "online"))
      |> Enum.map(fn %{"TransactionFee" => fee} = channel ->
        %PaymentChannel{
          code: channel["Code"],
          name: channel["Name"],
          description: channel["Description"],
          logo_url: if(code == "qris", do: "/images/qris-app.png", else: channel["Logo"]),
          doc_url: channel["PaymentInstructionsDoc"],
          trx_fee: fee["ActualFee"],
          trx_fee_type: fee["ActualFeeType"],
          additional_fee: fee["AdditionalFee"]
        }
      end)

    %PaymentChannelCategory{code: code, name: name, channels: channels}
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
  def create_redirect_transaction do
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

    App.PaymentGateway.Ipaymu.create_redirect_transaction(payload)
  end

  def get_transaction(id) do
    App.PaymentGateway.Ipaymu.get_transaction(id)
  end
end

# {:ok,
#  %{
#    "Channel" => "MPM",
#    "Escrow" => 0,
#    "Expired" => "2024-08-26 18:45:50",
#    "Fee" => 175,
#    "FeeDirection" => "MERCHANT",
#    "NMID" => "ID2020081400173",
#    "NNSCode" => "93600503",
#    "Note" => nil,
#    "PaymentName" => "iPaymu",
#    "PaymentNo" => "00020101021226670016COM.NOBUBANK.WWW01189360050300000488870214041800000314060303UKE51440014ID.CO.QRIS.WWW0215ID20200814001730303UKE5204549953033605405250005802ID5906iPaymu6008Denpasar61051581162810114082600031287420520202408261645507705550620202408261645507705550703A010804POSP63043355",
#    "QrImage" => "https://sandbox.ipaymu.com/qr/141759",
#    "QrString" => "00020101021226670016COM.NOBUBANK.WWW01189360050300000488870214041800000314060303UKE51440014ID.CO.QRIS.WWW0215ID20200814001730303UKE5204549953033605405250005802ID5906iPaymu6008Denpasar61051581162810114082600031287420520202408261645507705550620202408261645507705550703A010804POSP63043355",
#    "QrTemplate" => "https://sandbox.ipaymu.com/qr/template/141759",
#    "ReferenceId" => "7e64f44f-4819-436d-94f2-fe1034679ddb",
#    "SessionId" => "7e64f44f-4819-436d-94f2-fe1034679ddb",
#    "SubTotal" => 25000,
#    "Terminal" => "A01",
#    "Total" => 25000,
#    "TransactionId" => 141759,
#    "Via" => "QRIS"
#  }}

#  %{
#    "Channel" => "BRI",
#    "Escrow" => false,
#    "Expired" => "2024-08-26 18:51:55",
#    "Fee" => 3500,
#    "FeeDirection" => "MERCHANT",
#    "Note" => nil,
#    "PaymentName" => "iPaymu JetForm",
#    "PaymentNo" => "578893000189376",
#    "ReferenceId" => "7e64f44f-4819-436d-94f2-fe1034679ddb",
#    "SessionId" => "7e64f44f-4819-436d-94f2-fe1034679ddb",
#    "SubTotal" => 25000,
#    "Total" => 25000,
#    "TransactionId" => 141760,
#    "Via" => "VA"
#  }
