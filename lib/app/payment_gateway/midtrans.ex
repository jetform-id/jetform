defmodule App.PaymentGateway.Midtrans do
  @app_sandbox_base_url "https://app.sandbox.midtrans.com"
  @app_production_base_url "https://app.midtrans.com"

  @api_sandbox_base_url "https://api.sandbox.midtrans.com"
  @api_production_base_url "https://api.midtrans.com"

  def config_value(key) when is_binary(key) do
    config_value(String.to_atom(key))
  end

  def config_value(key) when is_atom(key) do
    case Application.get_env(:app, :midtrans)[key] do
      nil -> raise "Missing config :app, :midtrans, :#{key}"
      value -> value
    end
  end

  def create_transaction(%{} = payload) do
    get_app_base_url()
    |> get_http_client()
    |> Tesla.post("/snap/v1/transactions", payload)
    |> handle_response()
  end

  def cancel_transaction(order_id) do
    get_api_base_url()
    |> get_http_client()
    |> Tesla.post("/v2/#{order_id}/cancel", %{})
    |> handle_response()
  end

  def get_transaction_status(order_id) do
    get_api_base_url()
    |> get_http_client()
    |> Tesla.get("/v2/#{order_id}/status")
    |> handle_response()
  end

  def get_banks_list() do
    get_app_base_url()
    |> get_http_client()
    |> Tesla.get("/iris/api/v1/beneficiary_banks")
    |> handle_response()
  end

  def charge(%{} = payload) do
    get_api_base_url()
    |> get_http_client()
    |> Tesla.post("/v2/charge", payload)
    |> handle_response()
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

  defp handle_response({:ok, %{body: %{"token" => _, "redirect_url" => _} = body}}) do
    # create_transaction response
    {:ok, body}
  end

  defp handle_response({:ok, %{body: %{"error_messages" => errors}}}) do
    # create_transaction response
    {:error, errors}
  end

  defp handle_response({:ok, %{body: %{"transaction_id" => _} = body}}) do
    # get_status response
    {:ok, body}
  end

  defp handle_response({:ok, %{body: %{"status_message" => status_message}}}) do
    # get_status response
    {:error, status_message}
  end

  defp handle_response({:ok, %{status: status, body: body}}) do
    {:error, %{status_code: status, body: body}}
  end

  defp handle_response({:error, _} = error), do: error
end

defmodule App.PaymentGateway.Midtrans.Test do
  @transaction_payload %{
    "transaction_details" => %{
      "order_id" => "test_order_id",
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

  def create_gopay_charge do
    payload = ewallet_payload("gopay")
    App.PaymentGateway.Midtrans.charge(payload)
  end

  defp ewallet_payload(payment_type) do
    Map.put(@transaction_payload, "payment_type", payment_type)
  end
end
