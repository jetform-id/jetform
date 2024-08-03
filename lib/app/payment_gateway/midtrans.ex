defmodule App.PaymentGateway.Midtrans do
  @behaviour App.PaymentGateway.Provider

  alias App.Repo
  alias App.Orders.{Order, Payment}
  alias App.PaymentGateway.{ProviderInfo, CreateTransactionResult, GetTransactionResult}

  @app_sandbox_base_url "https://app.sandbox.midtrans.com"
  @app_production_base_url "https://app.midtrans.com"

  @api_sandbox_base_url "https://api.sandbox.midtrans.com"
  @api_production_base_url "https://api.midtrans.com"

  @impl true
  def id(), do: "midtrans"

  @impl true
  def info(), do: ProviderInfo.new("Midtrans", "https://midtrans.com")

  @impl true
  def config_value(key) when is_atom(key) do
    case Application.get_env(:app, :midtrans)[key] do
      nil -> raise "Missing config :app, :midtrans, :#{key}"
      value -> value
    end
  end

  def config_value(key) when is_binary(key) do
    config_value(String.to_atom(key))
  end

  @impl true
  def create_transaction(%{} = payload) do
    get_app_base_url()
    |> get_http_client()
    |> Tesla.post("/snap/v1/transactions", payload)
    |> case do
      {:ok, %{body: %{"token" => token, "redirect_url" => redirect_url}}} ->
        {:ok, CreateTransactionResult.new(token, redirect_url)}

      {:ok, %{body: %{"error_messages" => errors}}} ->
        {:error, errors}

      error ->
        error
    end
  end

  @impl true
  def cancel_transaction(id) do
    get_api_base_url()
    |> get_http_client()
    |> Tesla.post("/v2/#{id}/cancel", %{})
    |> case do
      {:ok, body} -> {:ok, body}
      error -> error
    end
  end

  @impl true
  def get_transaction(id) do
    get_api_base_url()
    |> get_http_client()
    |> Tesla.get("/v2/#{id}/status")
    |> case do
      {:ok, %{body: %{"transaction_id" => _} = body}} ->
        payment_type = body["payment_type"]
        {gross_amount, _} = body["gross_amount"] |> Integer.parse()

        transaction_status = body["transaction_status"]
        status_code = body["status_code"]
        fraud_status = body["fraud_status"]

        # paid: if all conditions are met (status, fraud_status, and status_code)
        trx_status =
          with true <- transaction_status in ["settlement", "capture"],
               "200" <- status_code,
               true <- fraud_status in ["accept", nil] do
            "paid"
          else
            _ -> transaction_status
          end

        result = %GetTransactionResult{
          payload: Jason.encode!(body),
          type: payment_type,
          trx_id: body["transaction_id"],
          trx_status: trx_status,
          fraud_status: fraud_status,
          status_code: status_code,
          gross_amount: gross_amount,
          fee: calculate_fee(gross_amount, payment_type)
        }

        {:ok, result}

      {:ok, %{body: %{"status_message" => status_message}}} ->
        {:error, status_message}

      error ->
        error
    end
  end

  @doc """
  Generate payload for Midtrans transactions API.

  To simplify payment time management, we strictly enforce te payment page expiry time as
  well as the transaction expiry time to the value of `expiry_in_minutes`.
  """
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

  @doc """
  Currently we only accept QRIS and bank transfer payment types.
  Calculations are based on: https://midtrans.com/pricing

  - qris: 0.7% of the transaction amount
  - bank_transfer: IDR 4,000
  """
  def calculate_fee(amount, payment_type) do
    case payment_type do
      "qris" -> trunc(amount * 0.007)
      "bank_transfer" -> 4_000
      _ -> 0
    end
  end

  @doc """
  Check the payload whether it belongs to correct merchant_id or
  has as valid signature.
  """
  @spec verify_payload(map) :: {:error, :invalid_payload} | {:ok, map}
  def verify_payload(
        %{
          "merchant_id" => merchant_id,
          "signature_key" => signature_key,
          "order_id" => order_id,
          "status_code" => status_code,
          "gross_amount" => gross_amount
        } = payload
      ) do
    computed_key =
      :crypto.hash(
        :sha512,
        "#{order_id}#{status_code}#{gross_amount}#{config_value(:server_key)}"
      )
      |> Base.encode16()
      |> String.downcase()

    case merchant_id == config_value(:merchant_id) and signature_key == computed_key do
      true -> {:ok, payload}
      false -> {:error, :invalid_payload}
    end
  end

  def verify_payload(_), do: {:error, :invalid_payload}

  defp get_app_base_url do
    case config_value(:mode) do
      "sandbox" -> @app_sandbox_base_url
      "production" -> @app_production_base_url
    end
  end

  defp get_api_base_url do
    case config_value(:mode) do
      "sandbox" -> @api_sandbox_base_url
      "production" -> @api_production_base_url
    end
  end

  defp get_auth_token do
    Base.encode64(config_value(:server_key) <> ":")
  end

  defp get_http_client(base_url) do
    headers = [
      {"accept", "application/json"},
      {"content-type", "application/json"},
      {"authorization", "Basic " <> get_auth_token()}
    ]

    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, headers}
    ]

    Tesla.client(middlewares)
  end
end

defmodule App.PaymentGateway.Midtrans.Test do
  @transaction_payload %{
    "transaction_details" => %{
      "order_id" => "test_order_id_101",
      "gross_amount" => 10000
    },
    "item_details" => [
      %{
        "id" => "test_item_id",
        "price" => 10000,
        "quantity" => 1,
        "name" => "Test Item",
        "brand" => "Test Brand",
        "merchant_name" => "Test Merchant"
      }
    ],
    "customer_details" => %{
      "first_name" => "test name",
      "email" => "test@example.com"
    },
    "expiry" => %{
      "unit" => "minutes",
      "duration" => 5
    },
    "page_expiry" => %{
      "duration" => 5,
      "unit" => "minutes"
    }
    # "enabled_payments" => ["other_qris"]
  }

  def create_transaction do
    App.PaymentGateway.Midtrans.create_transaction(@transaction_payload)
  end
end
