defmodule App.Midtrans do
  @app_sandbox_base_url "https://app.sandbox.midtrans.com"
  @app_production_base_url "https://app.midtrans.com"

  @api_sandbox_base_url "https://api.sandbox.midtrans.com"
  @api_production_base_url "https://api.midtrans.com"

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

  def test_create_transaction do
    payload = %{
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
    }

    create_transaction(payload)
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
    server_key = Application.get_env(:app, :midtrans_server_key)
    merch_id = Application.get_env(:app, :midtrans_merchant_id)

    computed_key =
      :crypto.hash(:sha512, "#{order_id}#{status_code}#{gross_amount}#{server_key}")
      |> Base.encode16()
      |> String.downcase()

    case merchant_id == merch_id and signature_key == computed_key do
      true -> {:ok, payload}
      false -> {:error, :invalid_payload}
    end
  end

  def verify_payload(_), do: {:error, :invalid_payload}

  defp get_app_base_url do
    case Application.get_env(:app, :midtrans_mode) do
      "sandbox" -> @app_sandbox_base_url
      "production" -> @app_production_base_url
    end
  end

  defp get_api_base_url do
    case Application.get_env(:app, :midtrans_mode) do
      "sandbox" -> @api_sandbox_base_url
      "production" -> @api_production_base_url
    end
  end

  defp get_auth_token do
    server_key = Application.get_env(:app, :midtrans_server_key, "")
    Base.encode64(server_key <> ":")
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
