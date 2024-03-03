defmodule App.Captcha do
  require Logger

  def verify_token(token) do
    config = Application.fetch_env!(:app, :captcha)

    Tesla.Multipart.new()
    |> Tesla.Multipart.add_field("response", token)
    |> Tesla.Multipart.add_field("secret", config[:secret_key])
    |> verify_token(config[:provider])
    |> handle_response()
  end

  defp handle_response({:ok, %{body: %{"success" => true}}}), do: :ok

  defp handle_response({:ok, %{body: %{"success" => false} = body}}) do
    Logger.error("Captcha verification failed, response: #{inspect(body)}")
    :error
  end

  defp handle_response({:error, reason}) do
    Logger.error("Calling captcha verification endpoint failed, reason: #{inspect(reason)}")
    :error
  end

  defp verify_token(body, "cloudflare") do
    http_client()
    |> Tesla.post("https://challenges.cloudflare.com/turnstile/v0/siteverify", body)
  end

  defp http_client() do
    headers = [
      {"accept", "application/json"}
    ]

    middlewares = [
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, headers}
    ]

    Tesla.client(middlewares)
  end
end
